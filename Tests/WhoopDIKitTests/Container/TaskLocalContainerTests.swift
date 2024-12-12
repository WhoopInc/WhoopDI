import WhoopDIKit
import Testing

class TaskLocalContainerTests: @unchecked Sendable {
    private let container: Container
    
    init() {
        let options = MockOptionProvider(options: [.taskLocalInject: true])
        container = Container(options: options)
    }

    @Test
    func inject() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory", "param")
        #expect(dependency is DependencyC)
    }

    @Test
    func inject_generic_integer() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: GenericDependency<Int> = container.inject()
        #expect(42 == dependency.value)
    }

    @Test
    func inject_generic_string() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: GenericDependency<String> = container.inject()
        #expect("string" == dependency.value)
    }

    @Test
    func inject_localDefinition() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory") { module in
            // Typically you'd override or provide a transient dependency. I'm using the top level dependency here
            // for the sake of simplicity.
            module.factory(name: "C_Factory") { DependencyA() as Dependency }
        }
        #expect(dependency is DependencyA)
    }

    @Test
    func inject_localDefinition_recursive() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory") { module in
            // Typically you'd override or provide a transient dependency. I'm using the top level dependency here
            // for the sake of simplicity.
            module.factory(name: "C_Factory") { self.container.inject() as DependencyA as Dependency }
        }
        #expect(dependency is DependencyA)
    }

    @Test
    func inject_localDefinition_inside_localDefinition() async throws {
        let dependency: Dependency = container.inject { module in
            module.factory {
                DependencyB(self.container.inject { innerModule in
                    innerModule.factory { "test_inner_module" }
                }) as Dependency
            }
        }
        #expect(dependency is DependencyB)
    }

    @Test(.bug("https://github.com/WhoopInc/WhoopDI/issues/13"))
    func inject_localDefinition_concurrency() async {
        container.registerModules(modules: [GoodTestModule()])
        // Run many times to try and capture race condition

        let taskA = Task.detached {
            for _ in 0..<500 {
                let _: Dependency = self.container.inject("C_Factory") { module in
                    module.factory(name: "C_Factory") { DependencyA() as Dependency }
                }
            }
        }

        let taskB = Task.detached {
            for _ in 0..<500 {
                let _: DependencyA = self.container.inject()
            }
        }

        for task in [taskA, taskB] {
            let _ = await task.result
        }
    }

    @Test
    func inject_localDefinition_noOverride() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory", params: "params") { _ in }
        #expect(dependency is DependencyC)
    }

    @Test
    func inject_localDefinition_withParams() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory", params: "params") { module in
            module.factoryWithParams(name: "C_Factory") { params in DependencyB(params) as Dependency }
        }
        #expect(dependency is DependencyB)
    }
    
    @Test
    func injectableWithDependency() throws {
        container.registerModules(modules: [FakeTestModuleForInjecting()])
        let testInjecting: InjectableWithDependency = container.inject()
        #expect(testInjecting == InjectableWithDependency(dependency: DependencyA()))
    }

    @Test
    func injectableWithNamedDependency() throws {
        container.registerModules(modules: [FakeTestModuleForInjecting()])
        let testInjecting: InjectableWithNamedDependency = container.inject()
        #expect(testInjecting == InjectableWithNamedDependency(name: 1))
    }
}
