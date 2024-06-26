import Foundation

public final class ServiceDictionary<Value> {
    private var valuesByType: [ServiceKey: Value]
    private let queue = DispatchQueue(label: "com.whoop.WhoopDI.serviceDictioanry", attributes: .concurrent)

    convenience public init() {
        self.init(valuesByType: [:])
    }
    
    private init(valuesByType: [ServiceKey: Value]) {
        self.valuesByType = valuesByType
    }

    public subscript<T>(key: T.Type) -> Value? {
        get {
            queue.sync {
                valuesByType[ServiceKey(key)]
            }
        }
        set {
            queue.async(flags: .barrier) {
                self.valuesByType[ServiceKey(key)] = newValue
            }
        }
    }

    public subscript(key: ServiceKey) -> Value? {
        get {
            queue.sync {
                valuesByType[key]
            }
        }
        set {
            queue.async(flags: .barrier) {
                self.valuesByType[key] = newValue
            }
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
