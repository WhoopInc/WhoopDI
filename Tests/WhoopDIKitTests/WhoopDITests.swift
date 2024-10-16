import Testing
@testable import WhoopDIKit

@MainActor
class WhoopDITests {
    @Test
    func inject() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = WhoopDI.inject("C_Factory", "param")
        #expect(dependency is DependencyC)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func inject_generic_integer() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: GenericDependency<Int> = WhoopDI.inject()
        #expect(42 == dependency.value)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func inject_generic_string() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: GenericDependency<String> = WhoopDI.inject()
        #expect("string" == dependency.value)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func inject_localDefinition() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = WhoopDI.inject("C_Factory") { module in
            // Typically you'd override or provide a transient dependency. I'm using the top level dependency here
            // for the sake of simplicity.
            module.factory(name: "C_Factory") { DependencyA() as Dependency }
        }
        #expect(dependency is DependencyA)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func inject_localDefinition_multipleInjections() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency1: Dependency = WhoopDI.inject("C_Factory") { module in
            module.factory(name: "C_Factory") { DependencyA() as Dependency }
        }
        let dependency2: Dependency = WhoopDI.inject("C_Factory", "params")
        let dependency3: Dependency = WhoopDI.inject("C_Factory") { module in
            module.factory(name: "C_Factory") { DependencyB("") as Dependency }
        }
        
        #expect(dependency1 is DependencyA)
        #expect(dependency2 is DependencyC)
        #expect(dependency3 is DependencyB)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func inject_localDefinition_noOverride() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = WhoopDI.inject("C_Factory", params: "params") { _ in }
        #expect(dependency is DependencyC)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func inject_localDefinition_withParams() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = WhoopDI.inject("C_Factory", params: "params") { module in
            module.factoryWithParams(name: "C_Factory") { params in DependencyB(params) as Dependency }
        }
        #expect(dependency is DependencyB)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func injectable() {
        WhoopDI.registerModules(modules: [FakeTestModuleForInjecting()])
        let testInjecting: InjectableWithNamedDependency = WhoopDI.inject()
        #expect(testInjecting == InjectableWithNamedDependency(name: 1))
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func setup() {
        // Verify nothing explocdes
        WhoopDI.setup(options: DefaultOptionProvider())
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func validation_fails_barParams() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let validator = WhoopDIValidator()
        var failed = false
        validator.validate { error in failed = true }
        #expect(failed)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func validation_fails_missingDependencies() {
        WhoopDI.registerModules(modules: [BadTestModule()])
        let validator = WhoopDIValidator()
        var failed = false
        validator.validate { error in
            let expectedKey = ServiceKey(Dependency.self, name: "A_Factory")
            let expectedError = DependencyError.missingDependency(expectedKey)
            #expect(expectedError == error as! DependencyError)
            failed = true
        }
        #expect(failed)
        WhoopDI.removeAllDependencies()
    }
    
    
    @Test
    func validation_fails_nilFactoryDependency() {
        WhoopDI.registerModules(modules: [NilFactoryModule()])
        let validator = WhoopDIValidator()
        var failed = false
        validator.validate { error in
            let expectedKey = ServiceKey(Optional<Dependency>.self)
            let expectedError = DependencyError.nilDependency(expectedKey)
            #expect(expectedError == error as! DependencyError)
            failed = true
        }
        #expect(failed)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func validation_fails_nilSingletonDependency() {
        WhoopDI.registerModules(modules: [NilSingletonModule()])
        let validator = WhoopDIValidator()
        var failed = false
        validator.validate { error in
            let expectedKey = ServiceKey(Optional<Dependency>.self)
            let expectedError = DependencyError.nilDependency(expectedKey)
            #expect(expectedError == error as! DependencyError)
            failed = true
        }
        #expect(failed)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func validation_succeeds() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let validator = WhoopDIValidator()
        validator.addParams("param", forType: Dependency.self, andName: "B_Factory")
        validator.addParams("param", forType: Dependency.self, andName: "B_Single")
        validator.addParams("param", forType: DependencyB.self)
        validator.addParams("param", forType: DependencyC.self)
        validator.addParams("param", forType: Dependency.self, andName: "C_Factory")
        
        validator.validate { error in
            Issue.record("DI failed with error: \(error)")
        }
        WhoopDI.removeAllDependencies()
    }
}
