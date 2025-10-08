import Foundation

protocol AccumulationDefinition {
    func getAccumulatedValue() throws -> Any
}

struct AccumulationDataDefinition: DependencyDefinition {
    var serviceKey: ServiceKey
    
    private let accumulationFunc: (Any, Any) throws -> Any
    private let defaultValue: (Container?) throws -> Any
    private var accumulatedDependencies: [AccumulationDefinition]

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
    }

    func get(params: Any?, container: Container) throws -> Any {
        try accumulatedDependencies.reduce(defaultValue(container.parent)) { partialResult, next in
            try accumulationFunc(partialResult, next.getAccumulatedValue())
        }
    }

    func insert(into serviceDictionary: ServiceDictionary<any DependencyDefinition>) {
        if let otherDefinition = serviceDictionary[self.serviceKey], var accumulatedDefinition = otherDefinition as? AccumulationDataDefinition {
            accumulatedDefinition.accumulatedDependencies.append(contentsOf: self.accumulatedDependencies)
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
