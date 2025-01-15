import Testing
@testable import WhoopDIKit

// This is unchecked Sendable so we can run our local inject concurrency test
class ContainerTests: @unchecked Sendable {
    private let container: Container
    
    init() {
        let options = MockOptionProvider(options: [.threadSafeLocalInject: true])
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
    
    @Test(.bug("https://github.com/WhoopInc/WhoopDI/issues/23"))
    func inject_localDefinition_dependenciesWithinLocalModule() {
        container.registerModules(modules: [BadTestModule()])
        let dependency: Dependency = container.inject("C_Factory", params: "params") { module in
            module.factoryWithParams(name: "C_Factory") { params in
                DependencyC(proto: try module.get("A_Factory"),
                            concrete: try module.get(params: params)) as Dependency
            }
            module.factory(name: "A_Factory") { DependencyA() as Dependency }
            module.factoryWithParams { params in DependencyB(params) }
        }
        #expect(dependency is DependencyC)
    }
    
    @Test(.bug("https://github.com/WhoopInc/WhoopDI/issues/13"))
    func inject_localDefinition_concurrency() async {
        container.registerModules(modules: [GoodTestModule()])
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
        let expected = InjectableWithNamedDependency(name: 1,
                                                     nameFromVariable: "variable",
                                                     globalVariableName: "global")
        #expect(testInjecting == expected)
    }
}
