import Foundation

/// Provides dependencies to the object graph. Modules can be registered with WhoopDI via `WhoopDI.registerModules`.
open class DependencyModule {
    private var dependencies: [DependencyDefinition] = []

    public init() {
    }
    
    /// Override this to provide the module dependencies for this module
    open var moduleDependencies: [DependencyModule] {
        []
    }
    
    open var serviceKey: ServiceKey {
        ServiceKey(type(of: self))
    }
    
    /// Defines a dependency which will be freshly created each time it is requested.
    /// - Parameters:
    ///     - name:  An optional name which can be used to disambiguate between multiple dependencies of the same type.
    ///     - factory: A closure which defines the dependency.
    /// - Returns: The dependency provided by the factory closure.
    public final func factory<T>(name: String? = nil, factory: @escaping () throws -> T) {
        dependencies.append(FactoryDefinition(name: name, factory: { _ in try factory() }))
    }
    
    /// Defines a dependency which will be freshly created each time it is requested. This version of the factory method provides parameters to the factory closure.
    /// The parameters are ultimately provided via the `inject` method of `WhoopDI`
    /// - Parameters:
    ///     - name:  An optional name which can be used to disambiguate between multiple dependencies of the same type.
    ///     - factory: A closure which defines the dependency.
    /// - Returns: The dependency provided by the factory closure.
    public final func factoryWithParams<T, Param>(name: String? = nil, factory: @escaping (Param) throws -> T) {
        dependencies.append(FactoryDefinition(name: name, factory: factoryConverter(name, factory)))
    }
    
    /// Defines a dependency which will be reused any time it is requested. The returned instance is effectively a non-static singleton.
    /// The parameters are ultimately provided via the `inject` method of `WhoopDI`
    /// - Parameters:
    ///     - name:  An optional name which can be used to disambiguate between multiple dependencies of the same type.
    ///     - factory: A closure which defines the dependency.
    /// - Returns: The dependency provided by the factory closure. This will be the same instance each time it is requested.
    public final func singleton<T>(name: String? = nil, factory: @escaping () throws -> T) {
        dependencies.append(SingletonDefinition(name: name, factory: { _ in try factory() }))
    }
    
    /// Defines a dependency which will be reused any time it is requested. The returned instance is effectively a non-static singleton. This version of the factory method provides parameters to the factory closure.
    /// The parameters are ultimately provided via the `inject` method of `WhoopDI`
    /// - Parameters:
    ///     - name:  An optional name which can be used to disambiguate between multiple dependencies of the same type.
    ///     - factory: A closure which defines the dependency.
    /// - Returns: The dependency provided by the factory closure. This will be the same instance each time it is requested.
    public final func singletonWithParams<T, Param>(name: String? = nil, factory: @escaping (Param) throws -> T) {
        dependencies.append(SingletonDefinition(name: name, factory: factoryConverter(name, factory)))
    }
    
    private func factoryConverter<T, Params>(_ name: String?, _ factory: @escaping (Params) throws -> T) -> (Any?) throws -> T {
        return { anyParams in
            guard let params = anyParams as? Params else {
                throw DependencyError.badParams(ServiceKey(T.self, name: name))
            }
            
            return try factory(params)
        }
    }
    
    /// Defines an accumulation that is recalculated on each request.
    /// Values are accumulated across the container hierarchy using the AccumulationKey's accumulate function.
    /// - Parameters:
    ///   - key: The AccumulationKey type that defines how values are accumulated
    ///   - provideValue: A closure that provides the value to accumulate
    public final func accumulateFactory<Key: AccumulationKey>(for key: Key.Type, provideValue: @escaping () throws -> Key.AccumulatedValue) {
        dependencies.append(FactoryAccumulationDefinition(accumulationKey: key, valueProvider: { _ in try provideValue() }))
    }

    /// Defines an accumulation that is recalculated on each request with parameters.
    /// Values are accumulated across the container hierarchy using the AccumulationKey's accumulate function.
    /// - Parameters:
    ///   - key: The AccumulationKey type that defines how values are accumulated
    ///   - provideValue: A closure that provides the value to accumulate, with parameters
    public final func accumulateFactoryWithParams<Key: AccumulationKey, Param>(for key: Key.Type, provideValue: @escaping (Param) throws -> Key.AccumulatedValue) {
        dependencies.append(FactoryAccumulationDefinition(accumulationKey: key, valueProvider: factoryConverter(nil, provideValue)))
    }

    /// Defines an accumulation that is calculated once and cached.
    /// Values are accumulated across the container hierarchy using the AccumulationKey's accumulate function.
    /// The accumulated value is computed once and reused on subsequent requests.
    /// - Parameters:
    ///   - key: The AccumulationKey type that defines how values are accumulated
    ///   - provideValue: A closure that provides the value to accumulate
    public final func accumulateSingleton<Key: AccumulationKey>(for key: Key.Type, provideValue: @escaping () throws -> Key.AccumulatedValue) {
        dependencies.append(SingletonAccumulationDefinition(accumulationKey: key, valueProvider: { _ in try provideValue() }))
    }

    /// Defines an accumulation that is calculated once and cached with parameters.
    /// Values are accumulated across the container hierarchy using the AccumulationKey's accumulate function.
    /// The accumulated value is computed once and reused on subsequent requests.
    /// - Parameters:
    ///   - key: The AccumulationKey type that defines how values are accumulated
    ///   - provideValue: A closure that provides the value to accumulate, with parameters
    public final func accumulateSingletonWithParams<Key: AccumulationKey, Param>(for key: Key.Type, provideValue: @escaping (Param) throws -> Key.AccumulatedValue) {
        dependencies.append(SingletonAccumulationDefinition(accumulationKey: key, valueProvider: factoryConverter(nil, provideValue)))
    }

    /// Fetches a dependency from the object graph. This is intended to be used within the factory closure provided to `factory`, `single`, etc.
    /// For example:
    /// ```
    /// factoryWithParams { params in
    ///        DependencyC(proto: try self.get("A_Factory"),
    ///                    concrete: try self.get(params: params))
    ///    }
    /// ```
    public final func get<T>(_ name: String? = nil, params: Any? = nil) throws -> T {
        if let containerWrapper = ContainerContext.currentContainer {
            return try containerWrapper.container.get(name, params)
        } else {
            return try WhoopDI.get(name, params)
        }
    }
    
    /// Implement this method to define your dependencies.
    open func defineDependencies() { }
    
    internal func addToServiceDictionary(serviceDict: ServiceDictionary<DependencyDefinition>) {
        dependencies.forEach { dependency in
            dependency.insert(into: serviceDict)
        }
    }
}

extension DependencyModule: Equatable {
    public static func == (lhs: DependencyModule, rhs: DependencyModule) -> Bool {
        lhs.serviceKey == rhs.serviceKey &&
        lhs.moduleDependencies == rhs.moduleDependencies
    }
}
