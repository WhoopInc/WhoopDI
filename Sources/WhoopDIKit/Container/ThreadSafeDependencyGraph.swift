import Foundation

final class ThreadSafeDependencyGraph: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private let serviceDict: ServiceDictionary<DependencyDefinition> = .init()
    private let options: WhoopDIOptionProvider
    
    // Add tracking for deadlocks
    nonisolated(unsafe) private static var activeThreads: [UInt64: String] = [:]
    private static let trackingLock = NSLock()
    
    init(options: WhoopDIOptionProvider) {
        self.options = options
    }
    
    func acquireDependencyGraph<T>(block: (ServiceDictionary<DependencyDefinition>) -> T) -> T {
        let threadSafe = options.isOptionEnabled(.threadSafeLocalInject)
        
        // Capture thread ID and type info
        let threadID = pthread_mach_thread_np(pthread_self())
        let typeName = String(describing: T.self)
        
        // Special handling for WHPBLEManager to force the deadlock
        let isWHPBLEManagerType = typeName.contains("WHPBLEManager")
        
        if isWHPBLEManagerType {
            print("🛑 Thread \(threadID) trying to acquire lock for WHPBLEManager")
            
            // Track this thread
            Self.trackingLock.lock()
            Self.activeThreads[UInt64(threadID)] = "WHPBLEManager"
            Self.printDeadlockStatus()
            Self.trackingLock.unlock()
            
            // Add delay before locking for WHPBLEManager to increase deadlock chance
            if threadSafe {
                print("🕒 Adding artificial delay before lock for WHPBLEManager on thread \(threadID)")
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
        
        // Actual lock acquisition
        if threadSafe {
            print("🔒 Thread \(threadID) attempting to lock for \(typeName)")
            lock.lock()
            print("✅ Thread \(threadID) acquired lock for \(typeName)")
        }
        
        let result = block(serviceDict)
        
        // If we're dealing with WHPBLEManager, add delay before releasing lock
        if threadSafe && isWHPBLEManagerType {
            print("⏳ Thread \(threadID) holding WHPBLEManager lock for 0.1s")
            Thread.sleep(forTimeInterval: 0.1) // Hold the lock longer to increase deadlock chance
        }
        
        // Release lock
        if threadSafe {
            print("🔓 Thread \(threadID) releasing lock for \(typeName)")
            lock.unlock()
            
            // Remove thread from tracking
            Self.trackingLock.lock()
            Self.activeThreads.removeValue(forKey: UInt64(threadID))
            Self.trackingLock.unlock()
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
    
    // Helper to print deadlock status
    private static func printDeadlockStatus() {
        if activeThreads.count > 1 {
            print("⚠️ POTENTIAL DEADLOCK DETECTED! ⚠️")
            print("Active threads waiting on locks:")
            for (threadID, typeName) in activeThreads {
                print("  Thread \(threadID): waiting for \(typeName)")
            }
        }
    }
}
