import Testing
@testable import WhoopDIKit

// This is unchecked Sendable so we can run our local inject concurrency test
class ContainerConcurrencyTests: @unchecked Sendable {
    let container: Container

    init() {
        let options = MockOptionProvider(options: [.threadSafeLocalInject: true])
        container = .init(modules: [GoodTestModule()], options: options)
    }

    @Test(.bug("https://github.com/WhoopInc/WhoopDI/issues/13"))
    func inject_localDefinition_concurrency() async {

        // Run many times to try and capture race condition
        for _ in 0..<500 {
            let taskA = Task.detached {
                let _: Dependency = self.container.inject("C_Factory") { module in
                    module.factory(name: "C_Factory") { DependencyA() as Dependency }
                }
            }
            
            let taskB = Task.detached {
                let _: DependencyA = self.container.inject()
            }
            
            for task in [taskA, taskB] {
                let _ = await task.result
            }
        }
    }
}
