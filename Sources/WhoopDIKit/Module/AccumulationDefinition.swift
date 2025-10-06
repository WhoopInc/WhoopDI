import Foundation

private func wrapAccumulationProvider<Key: AccumulationKey>(accumulationKey: Key.Type, valueProvider: @escaping (Any?) throws -> Key.AccumulatedValue) -> (Any?, Container) throws -> Any {
    return { (params: Any?, container: Container) throws -> Any in
        // Accumulate from the parent value if it exists, then add the current one
        let previousValueFromContainer: Key.FinalValue?
        do {
            previousValueFromContainer = try container.parent?.get(nil, params)
        } catch DependencyError.missingDependency(missingDependency: _, similarDependencies: _, dependencyCount: _) {
            previousValueFromContainer = nil // If there is no dependency, make it nil. Fail on other errors
        }
        return accumulationKey.accumulate(current: previousValueFromContainer ?? accumulationKey.defaultValue,
                                          next: try valueProvider(params))
    }
}


/// Provides the definition of an accumulation that is recalculated on each request.
/// A fresh accumulation will be computed each time it is requested.
final class FactoryAccumulationDefinition: DependencyDefinition {
    private let valueProvider: (Any?, Container) throws -> Any
    let serviceKey: ServiceKey

    init<Key: AccumulationKey>(accumulationKey: Key.Type, valueProvider: @escaping (Any?) throws -> Key.AccumulatedValue) {
        self.serviceKey = ServiceKey(Key.FinalValue.self)
        self.valueProvider = wrapAccumulationProvider(accumulationKey: accumulationKey, valueProvider: valueProvider)
    }

    func get(params: Any?, container: Container) throws -> Any {
        try valueProvider(params, container)
    }
}

/// Provides the definition of an accumulation that is calculated once and cached.
/// The accumulated value is computed once per container and reused on subsequent requests.
final class SingletonAccumulationDefinition: DependencyDefinition {
    private let accumulationKeyType: Any.Type
    private let valueProvider: (Any?, Container) throws -> Any
    private let lock = NSLock()
    let serviceKey: ServiceKey
    private var cachedValue: Any? = nil

    init<Key: AccumulationKey>(accumulationKey: Key.Type, valueProvider: @escaping (Any?) throws -> Key.AccumulatedValue) {
        self.accumulationKeyType = accumulationKey
        self.serviceKey = ServiceKey(Key.FinalValue.self)
        self.valueProvider = wrapAccumulationProvider(accumulationKey: accumulationKey, valueProvider: valueProvider)
    }

    func get(params: Any?, container: Container) throws -> Any {
        // Double-checked locking for the accumulated value
        if let value = cachedValue {
            return value
        }

        lock.lock()
        defer { lock.unlock() }

        if let value = cachedValue {
            return value
        }

        cachedValue = try valueProvider(params, container)
        return cachedValue!
    }

    func getAccumulationKeyType() -> Any.Type {
        accumulationKeyType
    }
}
