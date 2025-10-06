import Foundation

public final class Container {
    private let options: WhoopDIOptionProvider
    internal let parent: Container?

    private let serviceDict = ServiceDictionary<DependencyDefinition>()

    // For Legacy local inject.
    // When localInjectWithoutMutation is disabled these properties are used to lock the local service dictionary
    // so it can be used across multiple static calls to WhoopDI.inject. When that option is enabled we will no longer
    // support statically interacting with the local service dictionary.
    private let localDependencyGraph: ThreadSafeDependencyGraph
    private var isLocalInjectActive: Bool = false

    /// Creates a container and registers a list of modules with the DI system.
    /// Typically you will create a `DependencyModule` for your feature, then add it to the module list provided to this method.
    /// Each provided module and it's dependencies will be registered with the DI system.
    /// Dependencies are registered in dependency order, with leaf modules (those with no dependencies) being registered first.
    public init(modules: [DependencyModule] = [],
                parent: Container? = nil,
                options: WhoopDIOptionProvider = defaultWhoopDIOptions()) {
        self.parent = parent
        self.options = options
        localDependencyGraph = ThreadSafeDependencyGraph(options: options)
        registerModules(modules: modules)
    }

    /// Creates a container with a local module definition closure.
    /// This initializer allows you to define dependencies inline without creating a separate module.
    /// The dependencies defined in the closure will be registered with the DI system.
    ///
    /// Example:
    /// ```swift
    /// let container = Container { module in
    ///     module.factory { MyService() }
    ///     module.singleton { SharedService() }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - parent: An optional parent container to inherit dependencies from
    ///   - options: Configuration options for the DI system
    ///   - localDefinition: A closure that defines the dependencies for this container
    public init(parent: Container? = nil,
                options: WhoopDIOptionProvider = defaultWhoopDIOptions(),
                _ localDefinition: (DependencyModule) -> Void) {
        self.parent = parent
        self.options = options
        localDependencyGraph = ThreadSafeDependencyGraph(options: options)
        let localModule = DependencyModule()
        localDefinition(localModule)
        registerModules(modules: [localModule])
    }

    private func registerModules(modules: [DependencyModule]) {
        let tree = DependencyTree(dependencyModule: modules)
        tree.modules.forEach { module in
            module.defineDependencies()
            module.addToServiceDictionary(serviceDict: serviceDict)
        }
    }

    /// Injects a dependency into your code.
    ///
    /// The injected dependency will have all of it's sub-dependencies provided by the object graph defined in WhoopDI.
    /// Typically this should be called from your top level UI object (ViewController, etc). Intermediate components should rely upon constructor injection (i.e providing dependencies via the constructor)
    public func inject<T>(_ name: String? = nil, _ params: Any? = nil) -> T {
        return ContainerContext.withContainer(self) {
            do {
                return try get(name, params)
            } catch {
                print("Inject failed with stack trace:")
                Thread.callStackSymbols.forEach { print($0) }
                fatalError("WhoopDI inject failed with error: \(error)")
            }
        }
    }

    /// Injects a dependency into your code, overlaying local dependencies on top of the object graph.
    ///
    /// The injected dependency will have all of it's sub-dependencies provided by the object graph defined in WhoopDI.
    /// Typically this should be called from your top level UI object (ViewController, etc). Intermediate components should rely
    /// upon constructor injection (i.e providing dependencies via the constructor).
    ///
    /// This variant allows you to provide a local module definition which can be used to supply local dependencies to the object graph prior to injection.
    ///
    /// Example:
    /// ```swift
    /// let localDependency = MyLocalDependency()
    /// let myObject: MyObject = WhoopDI.inject { module in
    ///     module.factory { localDependency as LocalDependency }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - name: An optional name for the dependency. This can help disambiguate between dependencies of the same type.
    ///   - params: Optional parameters which will be provided to dependencies which require them (i.e dependencies using defintiions such as
    ///   (factoryWithParams, etc).
    ///   - localDefinition: A local module definition which can be used to supply local dependencies to the object graph prior to injection.
    /// - Returns: The requested dependency.
    public func inject<T>(_ name: String? = nil,
                          params: Any? = nil,
                          _ localDefinition: (DependencyModule) -> Void) -> T {
        guard options.isOptionEnabled(.localInjectWithoutMutation) else {
            return legacyLocalInject(name, params: params, localDefinition)
        }

        let localContainer = createChild(localDefinition)
        return localContainer.inject(name, params)
    }

    private func legacyLocalInject<T>(_ name: String? = nil,
                                      params: Any? = nil,
                                      _ localDefinition: (DependencyModule) -> Void) -> T {
        return ContainerContext.withContainer(self) {
            return localDependencyGraph.acquireDependencyGraph { localServiceDict in
                // Nested local injects are not currently supported. Fail fast here.
                guard !isLocalInjectActive else {
                    fatalError("Nesting WhoopDI.inject with local definitions is not currently supported")
                }

                isLocalInjectActive = true
                defer {
                    isLocalInjectActive = false
                    localDependencyGraph.resetDependencyGraph()
                }

                let localModule = DependencyModule()
                localDefinition(localModule)
                localModule.addToServiceDictionary(serviceDict: localServiceDict)

                do {
                    return try get(name, params)
                } catch {
                    print("Inject failed with stack trace:")
                    Thread.callStackSymbols.forEach { print($0) }
                    fatalError("WhoopDI inject failed with error: \(error)")
                }
            }
        }
    }

    /// Used internally by the DependencyModule get to loop up a sub-dependency in the object graph.
    func get<T>(_ name: String? = nil,
                _ params: Any? = nil) throws -> T {
        let serviceKey = ServiceKey(T.self, name: name)
        let definition = getDefinition(serviceKey)
        if let value = try definition?.get(params: params, container: self) as? T {
            return value
        } else if let parent = parent, let value = try parent.getDefinition(serviceKey)?.get(params: params, container: parent) as? T {
            return value
        } else if let injectable = T.self as? any Injectable.Type {
            return try injectable.inject(container: self) as! T
        } else  {
            throw DependencyError.createMissingDependencyError(missingDependency: ServiceKey(T.self, name: name),
                                                               serviceDict: serviceDict)
        }
    }

    /// Used internally via the `WhoopDIValidator` to verify all definitions in the object graph have definitions for their sub-dependencies  (i.e this verifies the object graph is complete).
    func validate(paramsDict: ServiceDictionary<Any>, onFailure: (Error) -> Void) {
        ContainerContext.withContainer(self) {
            serviceDict.allKeys().forEach { serviceKey in
                let definition = getDefinition(serviceKey)
                do {
                    let _ = try definition?.get(params: paramsDict[serviceKey], container: self)
                } catch {
                    onFailure(error)
                }
            }
        }
    }

    private func getDefinition(_ serviceKey: ServiceKey) -> DependencyDefinition? {
        guard options.isOptionEnabled(.localInjectWithoutMutation) else {
            return legacyGetDefinition(serviceKey)
        }

        return serviceDict[serviceKey]
    }

    private func legacyGetDefinition(_ serviceKey: ServiceKey) -> DependencyDefinition? {
        localDependencyGraph.acquireDependencyGraph { localServiceDict in
            return localServiceDict[serviceKey] ?? serviceDict[serviceKey]
        }
    }

    /// Creates a child container that inherits all dependencies from this container.
    /// Child containers can override parent dependencies and add new ones.
    /// This is useful for creating isolated dependency scopes or for testing.
    ///
    /// Example:
    /// ```swift
    /// let childContainer = container.createChild([MyModule(), OtherModule()])
    /// ```
    ///
    /// - Parameter modules: An array of dependency modules to register with the child container
    /// - Returns: A new container instance that inherits from this container
    public func createChild(_ modules: [DependencyModule] = []) -> Self {
        .init(modules: modules, parent: self, options: options)
    }

    /// Creates a child container that inherits all dependencies from this container.
    /// Child containers can override parent dependencies and add new ones.
    /// This is useful for creating isolated dependency scopes or for testing.
    ///
    /// Example:
    /// ```swift
    /// let childContainer = container.createChild { module in
    ///     module.factory { MockService() } // Override a parent dependency
    ///     module.factory { NewService() }  // Add a new dependency
    /// }
    /// ```
    ///
    /// - Parameter localDefinition: A closure that defines additional or overriding dependencies
    /// - Returns: A new container instance that inherits from this container
    public func createChild(_ localDefinition: (DependencyModule) -> Void) -> Self {
        .init(parent: self, options: options, localDefinition)
    }
}


