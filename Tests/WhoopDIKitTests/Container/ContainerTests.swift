import Testing
@testable import WhoopDIKit

class ContainerTests {
    @Test
    func inject() {
        let container = createContainer(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory", "param")
        #expect(dependency is DependencyC)
    }
    
    @Test
    func inject_generic_integer() {
        let container = createContainer(modules: [GoodTestModule()])
        let dependency: GenericDependency<Int> = container.inject()
        #expect(42 == dependency.value)
    }
    
    @Test
    func inject_generic_string() {
        let container = createContainer(modules: [GoodTestModule()])
        let dependency: GenericDependency<String> = container.inject()
        #expect("string" == dependency.value)
    }

    @Test
    func inject_dependencyTree() {
        let container = createContainer(modules: [ParentTestModule()])
        let dependency: Dependency = container.inject()
        #expect(dependency is DependencyC)
    }

    @Test
    func inject_localDefinition() {
        let container = createContainer(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory") { module in
            // Typically you'd override or provide a transient dependency. I'm using the top level dependency here
            // for the sake of simplicity.
            module.factory(name: "C_Factory") { DependencyA() as Dependency }
        }
        #expect(dependency is DependencyA)
    }
    
    @Test(.bug("https://github.com/WhoopInc/WhoopDI/issues/23"))
    func inject_localDefinition_dependenciesWithinLocalModule() {
        let container = createContainer(modules: [BadTestModule()])
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
    
    @Test
    func inject_localDefinition_noOverride() {
        let container = createContainer(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory", params: "params") { _ in }
        #expect(dependency is DependencyC)
    }
    
    @Test
    func inject_localDefinition_withParams() {
        let container = createContainer(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory", params: "params") { module in
            module.factoryWithParams(name: "C_Factory") { params in DependencyB(params) as Dependency }
        }
        #expect(dependency is DependencyB)
    }
    
    @Test
    func injectableWithDependency() throws {
        let container = createContainer(modules: [FakeTestModuleForInjecting()])
        let testInjecting: InjectableWithDependency = container.inject()
        #expect(testInjecting == InjectableWithDependency(dependency: DependencyA()))
    }
    
    @Test
    func injectableWithNamedDependency() throws {
        let container = createContainer(modules: [FakeTestModuleForInjecting()])
        let testInjecting: InjectableWithNamedDependency = container.inject()
        let expected = InjectableWithNamedDependency(name: 1,
                                                     nameFromVariable: "variable",
                                                     globalVariableName: "global")
        #expect(testInjecting == expected)
    }

    private func createContainer(modules: [DependencyModule]) -> Container {
        let options = MockOptionProvider(options: [.threadSafeLocalInject: true])
        return .init(modules: modules, options: options)
    }
}
