import Testing
@testable import WhoopDIKit

struct ThreadSafeDependencyGraphTests {
    @Test(arguments: [false, true])
    func aquireDependencyGraph_notThreadSafe(threadsafe: Bool) {
        let options = MockOptionProvider(options: [.threadSafeLocalInject: threadsafe])
        let graph = ThreadSafeDependencyGraph(options: options)
        
        graph.aquireDependencyGraph { serviceDict in
            serviceDict[DependencyA.self] = FactoryDefinition(name: nil) { _ in DependencyA() }
        }
        graph.aquireDependencyGraph { serviceDict in
            let dependency = serviceDict[DependencyA.self]
            #expect(dependency != nil)
        }
        
        graph.resetDependencyGraph()
        
        graph.aquireDependencyGraph { serviceDict in
            let dependency = serviceDict[DependencyA.self]
            #expect(dependency == nil)
        }
    }
    
    @Test
    func aquireDependencyGraph_recursive() {
        let options = MockOptionProvider(options: [.threadSafeLocalInject: true])
        let graph = ThreadSafeDependencyGraph(options: options)
        
        graph.aquireDependencyGraph { outer in
            graph.aquireDependencyGraph { serviceDict in
                serviceDict[DependencyA.self] = FactoryDefinition(name: nil) { _ in DependencyA() }
            }
            let dependency = outer[DependencyA.self]
            #expect(dependency != nil)
        }
    }
}
