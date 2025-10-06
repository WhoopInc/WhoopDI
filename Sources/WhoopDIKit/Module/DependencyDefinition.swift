import Foundation
protocol DependencyDefinition {
    var serviceKey: ServiceKey { get }
    func get(params: Any?, container: Container) throws -> Any
}

fileprivate extension DependencyDefinition {
    func verifyNotNil(value: Any) throws -> Any {
        if case Optional<Any>.none = value {
            throw DependencyError.nilDependency(serviceKey)
        }
        
        return value
    }
}

/// Provides the definition of an object factory. A fresh version of this dependency will be provide each time one is requested.
final class FactoryDefinition: DependencyDefinition {
    private let factory: (Any?) throws -> Any
    let serviceKey: ServiceKey
    
    init<T>(name: String?, factory: @escaping (Any?) throws -> T) {
        self.serviceKey = ServiceKey(T.self, name: name)
        self.factory = factory
    }
    
    func get(params: Any?, container: Container) throws -> Any {
        try verifyNotNil(value: factory(params))
    }
}

/// Provides the definition of a singleton object (i.e an object we will only create once per graph).
final class SingletonDefinition: DependencyDefinition {
    private let factory: (Any?) throws -> Any
    private let lock = NSLock()
    let serviceKey: ServiceKey
    var singletonValue: Any? = nil
    
    init<T>(name: String?, factory: @escaping (Any?) throws -> T) {
        self.serviceKey = ServiceKey(T.self, name: name)
        self.factory = factory
    }
    
    /// We need to use a locking mechanism in this version of get because we only want the singleton instance to get initialized exactly once.
    func get(params: Any?, container: Container) throws -> Any {
        // Double checked locking - check first if we already have a value.
        if let value = singletonValue {
            return value
        }
        // Nope, no value - lock again and check one more time to make sure it wasn't set from another thread, before we locked.
        lock.lock()
        defer { lock.unlock() }
        
        if let value = singletonValue {
            return value
        }
        
        singletonValue = try verifyNotNil(value: factory(params))
        
        return singletonValue! // The previous line ensures this isn't nil
    }
}
