import Foundation
public final class WhoopDI: DependencyRegister {
    private static let serviceDict = ServiceDictionary<DependencyDefinition>()
    private static var localServiceDict: ServiceDictionary<DependencyDefinition>? = nil
    
    /// Registers a list of modules with the DI system.
    /// Typically you will create a `DependencyModule` for your feature, then add it to the module list provided to this method.
    public static func registerModules(modules: [DependencyModule]) {
        modules.forEach { module in
            module.defineDependencies()
            module.addToServiceDictionary(serviceDict: serviceDict)
        }
    }
    
    /// Injects a dependecy into your code.
    ///
    /// The injected dependecy will have all of it's sub-dependencies provided by the object graph defined in WhoopDI.
    /// Typically this should be called from your top level UI object (ViewController, etc). Intermediate components should rely upon constructor injection (i.e providing dependencies via the constructor)
    public static func inject<T>(_ name: String? = nil, _ params: Any? = nil) -> T {
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
    /// The injected dependecy will have all of it's sub-dependencies provided by the object graph defined in WhoopDI.
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
    ///   - localDefiniton: A local module definition which can be used to supply local dependencies to the object graph prior to injection.
    /// - Returns: The requested dependency.
    public static func inject<T>(_ name: String? = nil,
                                 params: Any? = nil,
                                 _ localDefiniton: (DependencyModule) -> Void) -> T {
        guard localServiceDict == nil else {
            fatalError("Nesting WhoopDI.inject with local definitions is not currently supported")
        }
        // We need to maintain a reference to the local service dictionary because transient dependencies may also
        // need to reference dependencies from it.
        // ----
        // This is a little dangerous since we are mutating a static variable but it should be fine as long as you
        // don't use `inject { }` within the scope of another `inject { }`.
        let serviceDict = ServiceDictionary<DependencyDefinition>()
        localServiceDict = serviceDict
        defer {
            localServiceDict = nil
        }
        
        let localModule = DependencyModule()
        localDefiniton(localModule)
        localModule.addToServiceDictionary(serviceDict: serviceDict)
                
        do {
            return try get(name, params)
        } catch {
            fatalError("WhoopDI inject failed with error: \(error)")
        }
    }
    
    /// Used internally by the DependencyModule get to loop up a sub-dependency in the object graph.
    internal static func get<T>(_ name: String? = nil,
                                _ params: Any? = nil) throws -> T {
        let serviceKey = ServiceKey(T.self, name: name)
        let definition = getDefinition(serviceKey)
        if let value = try definition?.get(params: params) as? T {
            return value
        } else if let injectable = T.self as? any Injectable.Type {
            return try injectable.inject() as! T
        } else  {
            throw DependencyError.missingDependecy(ServiceKey(T.self, name: name))
        }
    }

    /// Used internally via the `WhoopDIValidator` to verify all definitions in the object graph have definitions for their sub-dependencies  (i.e this verifies the object graph is complete).
    internal static func validate(paramsDict: ServiceDictionary<Any>, onFailure: (Error) -> Void) {
        serviceDict.allKeys().forEach { serviceKey in
            let definition = getDefinition(serviceKey)
            do {
                let _ = try definition?.get(params: paramsDict[serviceKey])
            } catch {
                onFailure(error)
            }
        }
    }
    
    private static func getDefinition(_ serviceKey: ServiceKey) -> DependencyDefinition? {
        return localServiceDict?[serviceKey] ?? serviceDict[serviceKey]
    }
    
    public static func removeAllDependencies() {
        serviceDict.removeAll()
    }
}
