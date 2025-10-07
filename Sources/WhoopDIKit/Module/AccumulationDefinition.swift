import Foundation

private func wrapAccumulationProvider<Key: AccumulationKey>(name: String?, accumulationKey: Key.Type, valueProvider: @escaping (Any?) throws -> Key.AccumulatedValue) -> (Any?, Container) throws -> Any {
    return { (params: Any?, container: Container) throws -> Any in
        // Accumulate from the parent value if it exists, then add the current one
        let previousValueFromContainer: Key.FinalValue?
        do {
            if let parent = container.parent {
                let value: Key.FinalValue = try parent.get(name, params)
                previousValueFromContainer = value
            } else {
                previousValueFromContainer = nil
            }
        } catch DependencyError.missingDependency {
            previousValueFromContainer = nil // If there is no dependency, make it nil. Fail on other errors
        }
        return accumulationKey.accumulate(current: previousValueFromContainer ?? accumulationKey.defaultValue,
                                          next: try valueProvider(params))
    }
}

private func accumulate<Key: AccumulationKey>(key: Key.Type,
                                              definition: DependencyDefinition,
                                              accumulatedValueGetter: @escaping (Any?) throws -> Key.AccumulatedValue,
                                              serviceDictionary: ServiceDictionary<DependencyDefinition>) {
    if let value = serviceDictionary[definition.serviceKey] {
        serviceDictionary[definition.serviceKey] = FactoryDefinition(name: nil, factory: { params, container in
            guard let currentValue = try value.get(params: params, container: container) as? Key.FinalValue else {
                fatalError() // This basically shouldn't be possible since we have two things with the same service key, but totally different value types
            }
            return try key.accumulate(current: currentValue, next: accumulatedValueGetter(params))
        })
    } else {
        serviceDictionary[definition.serviceKey] = definition
    }
}


/// Provides the definition of an accumulation that is recalculated on each request.
/// A fresh accumulation will be computed each time it is requested.
final class FactoryAccumulationDefinition: DependencyDefinition {
    private let valueProvider: (Any?, Container) throws -> Any
    private let insertionFunc: (ServiceDictionary<DependencyDefinition>, FactoryAccumulationDefinition) -> Void
    let serviceKey: ServiceKey

    init<Key: AccumulationKey>(name: String?, accumulationKey: Key.Type, valueProvider: @escaping (Any?) throws -> Key.AccumulatedValue) {
        self.serviceKey = ServiceKey(Key.FinalValue.self, name: name)
        self.valueProvider = wrapAccumulationProvider(name: name, accumulationKey: accumulationKey, valueProvider: valueProvider)
        self.insertionFunc = { dictionary, definition in accumulate(key: accumulationKey,
                                                                    definition: definition,
                                                                    accumulatedValueGetter: valueProvider,
                                                                    serviceDictionary: dictionary)
        }
    }

    func get(params: Any?, container: Container) throws -> Any {
        try valueProvider(params, container)
    }

    func insert(into serviceDictionary: ServiceDictionary<any DependencyDefinition>) {
        insertionFunc(serviceDictionary, self)
    }
}

/// Provides the definition of an accumulation that is calculated once and cached.
/// The accumulated value is computed once per container and reused on subsequent requests.
final class SingletonAccumulationDefinition: DependencyDefinition {
    private let accumulationKeyType: Any.Type
    private let valueProvider: (Any?, Container) throws -> Any
    private let lock = NSLock()
    let serviceKey: ServiceKey
    private let insertionFunc: (ServiceDictionary<DependencyDefinition>, SingletonAccumulationDefinition) -> Void
    private var cachedAccumulated: Any? = nil
    private var cachedValue: Any? = nil

    init<Key: AccumulationKey>(name: String?, accumulationKey: Key.Type, valueProvider: @escaping (Any?) throws -> Key.AccumulatedValue) {
        self.accumulationKeyType = accumulationKey
        self.serviceKey = ServiceKey(Key.FinalValue.self, name: name)
        self.valueProvider = wrapAccumulationProvider(name: name, accumulationKey: accumulationKey, valueProvider: valueProvider)
        self.insertionFunc = { dictionary, definition in accumulate(key: accumulationKey,
                                                                    definition: definition,
                                                                    accumulatedValueGetter: { params in
            try definition.lockValue(externalGet: {
                try valueProvider(params)
            }, cache: \.cachedAccumulated)
        },
                                                                    serviceDictionary: dictionary)
        }
    }

    private func lockValue<T>(externalGet: () throws -> T, cache: ReferenceWritableKeyPath<SingletonAccumulationDefinition, Any?>) throws -> T {
        if let value = self[keyPath: cache] {
            // Double-checked locking for the accumulated value
            return value as! T
        }

        lock.lock()
        defer { lock.unlock() }

        if let value = self[keyPath: cache] {
            return value as! T
        }

        let value = try externalGet()

        self[keyPath: cache] = value
        return value

    }

    func get(params: Any?, container: Container) throws -> Any {
        return try lockValue(externalGet: {
            try self.valueProvider(params, container)
        }, cache: \.cachedValue)
    }

    func insert(into serviceDictionary: ServiceDictionary<any DependencyDefinition>) {
        insertionFunc(serviceDictionary, self)
    }

}
