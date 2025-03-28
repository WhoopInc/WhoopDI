import Testing
@testable import WhoopDIKit

@MainActor
class WhoopDITests {
    @Test
    func inject() {
        WhoopDI.setup(modules: [GoodTestModule()])
        let dependency: Dependency = WhoopDI.inject("C_Factory", "param")
        #expect(dependency is DependencyC)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func inject_generic_integer() {
        WhoopDI.setup(modules: [GoodTestModule()])
        let dependency: GenericDependency<Int> = WhoopDI.inject()
        #expect(42 == dependency.value)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func inject_generic_string() {
        WhoopDI.setup(modules: [GoodTestModule()])
        let dependency: GenericDependency<String> = WhoopDI.inject()
        #expect("string" == dependency.value)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func inject_localDefinition() {
        WhoopDI.setup(modules: [GoodTestModule()])
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
        WhoopDI.setup(modules: [GoodTestModule()])
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
        WhoopDI.setup(modules: [GoodTestModule()])
        let dependency: Dependency = WhoopDI.inject("C_Factory", params: "params") { _ in }
        #expect(dependency is DependencyC)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func inject_localDefinition_withParams() {
        WhoopDI.setup(modules: [GoodTestModule()])
        let dependency: Dependency = WhoopDI.inject("C_Factory", params: "params") { module in
            module.factoryWithParams(name: "C_Factory") { params in DependencyB(params) as Dependency }
        }
        #expect(dependency is DependencyB)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func injectable() {
        WhoopDI.setup(modules: [FakeTestModuleForInjecting()])
        let testInjecting: InjectableWithNamedDependency = WhoopDI.inject()
        let expected = InjectableWithNamedDependency(name: 1,
                                                     nameFromVariable: "variable",
                                                     globalVariableName:  "global")
        #expect(testInjecting == expected)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func setup() {
        // Verify nothing explocdes
        WhoopDI.setup(modules: [], options: DefaultOptionProvider())
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func validation_fails_barParams() {
        WhoopDI.setup(modules: [GoodTestModule()])
        let validator = WhoopDIValidator()
        var failed = false
        validator.validate { error in failed = true }
        #expect(failed)
        WhoopDI.removeAllDependencies()
    }
    
    @Test
    func validation_fails_missingDependencies() {
        WhoopDI.setup(modules: [BadTestModule()])
        let validator = WhoopDIValidator()
        var failed = false
        validator.validate { error in
            let expectedKey = ServiceKey(Dependency.self, name: "A_Factory")
            let expectedError = DependencyError.missingDependency(missingDependency: expectedKey,
                                                                  similarDependencies: Set(),
                                                                  dependencyCount: 1)
            #expect(expectedError == error as! DependencyError)
            failed = true
        }
        #expect(failed)
        WhoopDI.removeAllDependencies()
    }
    
    
    @Test
    func validation_fails_nilFactoryDependency() {
        WhoopDI.setup(modules: [NilFactoryModule()])
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
        WhoopDI.setup(modules: [NilSingletonModule()])
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
        WhoopDI.setup(modules: [GoodTestModule()])
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
