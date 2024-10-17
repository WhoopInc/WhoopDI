import Testing
@testable import WhoopDIKit

struct ThreadSafeDependencyGraphTests {
    @Test(arguments: [false, true])
    func acquireDependencyGraph_notThreadSafe(threadsafe: Bool) {
        let options = MockOptionProvider(options: [.threadSafeLocalInject: threadsafe])
        let graph = ThreadSafeDependencyGraph(options: options)
        
        graph.acquireDependencyGraph { serviceDict in
            serviceDict[DependencyA.self] = FactoryDefinition(name: nil) { _ in DependencyA() }
        }
        graph.acquireDependencyGraph { serviceDict in
            let dependency = serviceDict[DependencyA.self]
            #expect(dependency != nil)
        }
        
        graph.resetDependencyGraph()
        
        graph.acquireDependencyGraph { serviceDict in
            let dependency = serviceDict[DependencyA.self]
            #expect(dependency == nil)
        }
    }
    
    @Test
    func acquireDependencyGraph_recursive() {
        let options = MockOptionProvider(options: [.threadSafeLocalInject: true])
        let graph = ThreadSafeDependencyGraph(options: options)
        
        graph.acquireDependencyGraph { outer in
            graph.acquireDependencyGraph { serviceDict in
                serviceDict[DependencyA.self] = FactoryDefinition(name: nil) { _ in DependencyA() }
            }
            let dependency = outer[DependencyA.self]
            #expect(dependency != nil)
        }
    }
}
