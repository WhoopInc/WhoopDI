import Foundation
public final class Container {
    private let localDependencyGraph: ThreadSafeDependencyGraph
    private var isLocalInjectActive: Bool = false
    private let options: WhoopDIOptionProvider
    
    private let serviceDict = ServiceDictionary<DependencyDefinition>()

    public init(options: WhoopDIOptionProvider = defaultWhoopDIOptions()) {
        self.options = options
        localDependencyGraph = ThreadSafeDependencyGraph(options: options)
    }

    /// Registers a list of modules with the DI system.
    /// Typically you will create a `DependencyModule` for your feature, then add it to the module list provided to this method.
    public func registerModules(modules: [DependencyModule]) {
        modules.forEach { module in
            module.container = self
            module.defineDependencies()
            module.addToServiceDictionary(serviceDict: serviceDict)
        }
    }

    /// Injects a dependency into your code.
    ///
    /// The injected dependency will have all of it's sub-dependencies provided by the object graph defined in WhoopDI.
    /// Typically this should be called from your top level UI object (ViewController, etc). Intermediate components should rely upon constructor injection (i.e providing dependencies via the constructor)
    public func inject<T>(_ name: String? = nil, _ params: Any? = nil) -> T {
        do {
            return try get(name, params)
        } catch {
            print("Inject failed with stack trace:")
            Thread.callStackSymbols.forEach { print($0) }
            fatalError("WhoopDI inject failed with error: \(error)")
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
            localModule.container = self
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

    /// Used internally by the DependencyModule get to loop up a sub-dependency in the object graph.
    func get<T>(_ name: String? = nil,
                _ params: Any? = nil) throws -> T {
        let serviceKey = ServiceKey(T.self, name: name)
        let definition = getDefinition(serviceKey)
        if let value = try definition?.get(params: params) as? T {
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
        serviceDict.allKeys().forEach { serviceKey in
            let definition = getDefinition(serviceKey)
            do {
                let _ = try definition?.get(params: paramsDict[serviceKey])
            } catch {
                onFailure(error)
            }
        }
    }

    private func getDefinition(_ serviceKey: ServiceKey) -> DependencyDefinition? {
        localDependencyGraph.acquireDependencyGraph { localServiceDict in
            return localServiceDict[serviceKey] ?? serviceDict[serviceKey]
        }
    }

    public func removeAllDependencies() {
        serviceDict.removeAll()
    }
}


