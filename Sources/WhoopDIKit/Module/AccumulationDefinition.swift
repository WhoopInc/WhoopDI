import Foundation

/// Base protocol for accumulation definitions to enable type-safe accumulation in Container
protocol AccumulationDefinitionProtocol: DependencyDefinition {
    func getAccumulationKeyType() -> Any.Type
}

/// Provides the definition of an accumulation that is recalculated on each request.
/// A fresh accumulation will be computed each time it is requested.
final class FactoryAccumulationDefinition: AccumulationDefinitionProtocol {
    private let accumulationKeyType: Any.Type
    private let valueProvider: (Any?) throws -> Any
    let serviceKey: ServiceKey

    init<Key: AccumulationKey>(accumulationKey: Key.Type, valueProvider: @escaping (Any?) throws -> Key.AccumulatedValue) {
        self.accumulationKeyType = accumulationKey
        self.serviceKey = ServiceKey(Key.FinalValue.self)
        self.valueProvider = { params in try valueProvider(params) }
    }

    func get(params: Any?) throws -> Any {
        try valueProvider(params)
    }

    func getAccumulationKeyType() -> Any.Type {
        accumulationKeyType
    }
}

/// Provides the definition of an accumulation that is calculated once and cached.
/// The accumulated value is computed once per container and reused on subsequent requests.
final class SingletonAccumulationDefinition: AccumulationDefinitionProtocol {
    private let accumulationKeyType: Any.Type
    private let valueProvider: (Any?) throws -> Any
    private let lock = NSLock()
    let serviceKey: ServiceKey
    private var cachedValue: Any? = nil

    init<Key: AccumulationKey>(accumulationKey: Key.Type, valueProvider: @escaping (Any?) throws -> Key.AccumulatedValue) {
        self.accumulationKeyType = accumulationKey
        self.serviceKey = ServiceKey(Key.FinalValue.self)
        self.valueProvider = { params in try valueProvider(params) }
    }

    func get(params: Any?) throws -> Any {
        // Double-checked locking for the accumulated value
        if let value = cachedValue {
            return value
        }

        lock.lock()
        defer { lock.unlock() }

        if let value = cachedValue {
            return value
        }

        cachedValue = try valueProvider(params)
        return cachedValue!
    }

    func getAccumulationKeyType() -> Any.Type {
        accumulationKeyType
    }
}
