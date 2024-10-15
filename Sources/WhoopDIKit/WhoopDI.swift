import Foundation
public final class WhoopDI: DependencyRegister {
    nonisolated(unsafe) static let appContainer = Container()
    
    /// Registers a list of modules with the DI system.
    /// Typically you will create a `DependencyModule` for your feature, then add it to the module list provided to this method.
    public static func registerModules(modules: [DependencyModule]) {
        appContainer.registerModules(modules: modules)
    }
    
    /// Injects a dependecy into your code.
    ///
    /// The injected dependecy will have all of it's sub-dependencies provided by the object graph defined in WhoopDI.
    /// Typically this should be called from your top level UI object (ViewController, etc). Intermediate components should rely upon constructor injection (i.e providing dependencies via the constructor)
    public static func inject<T>(_ name: String? = nil, _ params: Any? = nil) -> T {
        appContainer.inject(name, params)
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
        appContainer.inject(name, params: params, localDefiniton)
    }
    
    /// Used internally by the DependencyModule get to loop up a sub-dependency in the object graph.
    internal static func get<T>(_ name: String? = nil,
                                _ params: Any? = nil) throws -> T {
        try appContainer.get(name, params)
    }

    /// Used internally via the `WhoopDIValidator` to verify all definitions in the object graph have definitions for their sub-dependencies  (i.e this verifies the object graph is complete).
    internal static func validate(paramsDict: ServiceDictionary<Any>, onFailure: (Error) -> Void) {
        appContainer.validate(paramsDict: paramsDict, onFailure: onFailure)
    }
    
    public static func removeAllDependencies() {
        appContainer.removeAllDependencies()
    }
}
