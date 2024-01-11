public final class ServiceDictionary<Value> {
    private var valuesByType: [ServiceKey: Value]

    convenience public init() {
        self.init(valuesByType: [:])
    }
    
    private init(valuesByType: [ServiceKey: Value]) {
        self.valuesByType = valuesByType
    }

    public subscript<T>(key: T.Type) -> Value? {
        get {
            valuesByType[ServiceKey(key)]
        }
        set {
            valuesByType[ServiceKey(key)] = newValue
        }
    }

    public subscript(key: ServiceKey) -> Value? {
        get {
            valuesByType[key]
        }
        set {
            valuesByType[key] = newValue
        }
    }
    
    public func allKeys() -> Set<ServiceKey> {
        Set(valuesByType.keys)
    }
    
    public func removeAll() {
        valuesByType.removeAll()
    }
}

public extension ServiceDictionary {
    static func + (left: ServiceDictionary<Value>, right: ServiceDictionary<Value>) -> ServiceDictionary<Value> {
        let merged = left.valuesByType.merging(right.valuesByType) { (_, last) in last }
        return ServiceDictionary<Value>(valuesByType: merged)
    }
}
