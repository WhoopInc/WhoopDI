import Foundation

protocol DefinitionDictionaryProvider {
    func provide<T>(_ providerFunc: (ServiceDictionary<DependencyDefinition>) -> T) -> T
}

extension DefinitionDictionaryProvider {
    static func standard() -> DefinitionDictionaryProvider {
        StandardDefinitionDictionaryProvider()
    }
    
    static func threadSafe() -> DefinitionDictionaryProvider {
        ThreadSafeDefinitionDictionaryProvider()
    }
}

struct StandardDefinitionDictionaryProvider: DefinitionDictionaryProvider {
    private let serviceDict = ServiceDictionary<DependencyDefinition>()
    
    func provide<T>(_ providerFunc: (ServiceDictionary<DependencyDefinition>) -> T) -> T {
        providerFunc(serviceDict)
    }
}

struct ThreadSafeDefinitionDictionaryProvider: DefinitionDictionaryProvider {
    private let lock = NSLock()
    private let serviceDict = ServiceDictionary<DependencyDefinition>()
    
    func provide<T>(_ providerFunc: (ServiceDictionary<DependencyDefinition>) -> T) -> T {
        lock.lock()
        let result = providerFunc(serviceDict)
        lock.unlock()
        
        return result
    }
}
