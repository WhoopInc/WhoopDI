import Foundation

final class ThreadSafeDependencyGraph: Sendable {
    private let lock = NSRecursiveLock()
    nonisolated(unsafe) private let serviceDict: ServiceDictionary<DependencyDefinition> = .init()
    private let options: WhoopDIOptionProvider
    
    init(options: WhoopDIOptionProvider) {
        self.options = options
    }
    
    func aquireDependencyGraph<T>(block: (ServiceDictionary<DependencyDefinition>) -> T) -> T {
        let threadSafe = options.isOptionEnabled(.threadSafeLocalInject)
        if threadSafe {
            lock.lock()
        }
        let result = block(serviceDict)
        if threadSafe {
            lock.unlock()
        }
        return result
    }
    
    func resetDependencyGraph() {
        let threadSafe = options.isOptionEnabled(.threadSafeLocalInject)
        if threadSafe {
            lock.lock()
        }
        serviceDict.removeAll()
        if threadSafe {
            lock.unlock()
        }
    }
    
}
