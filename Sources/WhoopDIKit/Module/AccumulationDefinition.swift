import Foundation

protocol AccumulationDefinition {
    func getAccumulatedValue() throws -> Any
}

class AccumulationDataDefinition: DependencyDefinition {
    var serviceKey: ServiceKey
    
    private let accumulationFunc: (Any, Any) throws -> Any
    private let defaultValue: (Container?) throws -> Any
    private var accumulatedDependencies: [AccumulationDefinition]
    private var shouldCacheValue: Bool
    private let lock = NSLock()
    private var cachedValue: Any?

    init<Key: AccumulationKey>(name: String? = nil, key: Key.Type, accumulatedDependencies: [AccumulationDefinition] = []) {
        self.serviceKey = ServiceKey(Key.FinalValue.self, name: name)
        self.accumulationFunc = { accumulated, next in
            key.accumulate(current: accumulated as! Key.FinalValue, next: next as! Key.AccumulatedValue)
        }
        self.defaultValue = { parent in
            if let parent {
                do {
                    let topLevel: Key.FinalValue = try parent.get(name, nil)
                    return topLevel
                } catch DependencyError.missingDependency {
                    return key.defaultValue
                }
            } else {
                return key.defaultValue
            }
        }
        self.accumulatedDependencies = accumulatedDependencies
        self.shouldCacheValue = accumulatedDependencies.allSatisfy { definition in definition is SingletonAccumulationDefinition }
    }

    func get(params: Any?, container: Container) throws -> Any {
        if shouldCacheValue {
            if let cachedValue {
                return cachedValue
            }

            lock.lock()
            defer { lock.unlock() }
            if let cachedValue {
                return cachedValue
            }

            let newValue = try self.getAccumulatedValue(container: container)
            cachedValue = newValue
            return newValue

        } else {
            return try getAccumulatedValue(container: container)
        }

    }

    private func getAccumulatedValue(container: Container) throws -> Any {
        try accumulatedDependencies.reduce(defaultValue(container.parent)) { partialResult, next in
            try accumulationFunc(partialResult, next.getAccumulatedValue())
        }
    }

    func insert(into serviceDictionary: ServiceDictionary<any DependencyDefinition>) {
        if let otherDefinition = serviceDictionary[self.serviceKey], let accumulatedDefinition = otherDefinition as? AccumulationDataDefinition {
            accumulatedDefinition.accumulatedDependencies.append(contentsOf: self.accumulatedDependencies)
            accumulatedDefinition.shouldCacheValue = accumulatedDefinition.shouldCacheValue && self.shouldCacheValue
            serviceDictionary[self.serviceKey] = accumulatedDefinition
        } else { // If we aren't already accumulating, we are done
            serviceDictionary[self.serviceKey] = self
        }
    }
}

/// Provides the definition of an accumulation that is recalculated on each request.
/// A fresh accumulation will be computed each time it is requested.
final class FactoryAccumulationDefinition: AccumulationDefinition {
    private let valueProvider: () throws -> Any

    init<Key: AccumulationKey>(accumulationKey: Key.Type, valueProvider: @escaping () throws -> Key.AccumulatedValue) {
        self.valueProvider = valueProvider
    }

    func getAccumulatedValue() throws -> Any {
        try valueProvider()
    }
}

/// Provides the definition of an accumulation that is calculated once and cached.
/// The accumulated value is computed once per container and reused on subsequent requests.
final class SingletonAccumulationDefinition: AccumulationDefinition {
    private let lock = NSLock()
    private var cachedAccumulated: Any? = nil
    private let valueProvider: () throws -> Any

    init<Key: AccumulationKey>(accumulationKey: Key.Type, valueProvider: @escaping () throws -> Key.AccumulatedValue) {
        self.valueProvider = valueProvider
    }

    func getAccumulatedValue() throws -> Any {
        if let value = self.cachedAccumulated {
            // Double-checked locking for the accumulated value
            return value
        }

        lock.lock()
        defer { lock.unlock() }

        if let value = self.cachedAccumulated {
            return value
        }

        let value = try valueProvider()

        self.cachedAccumulated = value
        return value
    }

}
