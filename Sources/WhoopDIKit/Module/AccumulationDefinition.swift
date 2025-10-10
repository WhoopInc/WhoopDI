import Foundation

class AccumulationDataDefinition: DependencyDefinition {
    let serviceKey: ServiceKey

    private let accumulationFunc: (Any, Any) throws -> Any
    private let defaultValue: (Container?) throws -> Any
    private var accumulatedDependencies: [DependencyDefinition]
    private var shouldCacheValue: Bool
    private let lock = NSLock()
    private var cachedValue: Any?

    init<Key: AccumulationKey>(name: String? = nil,
                               key: Key.Type,
                               accumulatedDependency: DependencyDefinition) {
        self.serviceKey = ServiceKey(Key.FinalValue.self, name: name)
        self.accumulationFunc = { accumulated, next in
            // Since we only create the values internally (and use the same service key, which has the same type)
            // we can force cast here.
            key.accumulate(current: accumulated as! Key.FinalValue, next: next as! Key.AccumulatedValue)
        }
        self.defaultValue = { parent in
            // Try to get the previously accumulated value from the parent
            // If there is none, use the initial value
            // If another error occurs other than missingDependency, throw it
            if let parent {
                do {
                    let topLevel: Key.FinalValue = try parent.get(name, nil)
                    return topLevel
                } catch DependencyError.missingDependency {
                    return key.initialValue
                }
            } else {
                return key.initialValue
            }
        }
        self.accumulatedDependencies = [accumulatedDependency]
        self.shouldCacheValue = accumulatedDependency is SingletonDefinition
    }

    func get(params: Any?, parent: Container?) throws -> Any {
        if shouldCacheValue {
            if let cachedValue {
                return cachedValue
            }

            lock.lock()
            defer { lock.unlock() }
            if let cachedValue {
                return cachedValue
            }

            let newValue = try self.getAccumulatedValue(parent: parent)
            cachedValue = newValue
            return newValue

        } else {
            return try getAccumulatedValue(parent: parent)
        }

    }

    private func getAccumulatedValue(parent: Container?) throws -> Any {
        try accumulatedDependencies.reduce(defaultValue(parent)) { partialResult, next in
            try accumulationFunc(partialResult, next.get(params: nil, parent: parent))
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
