import XCTest
@testable import WhoopDIKit

class WhoopDITests: XCTestCase {
    
    override func tearDown() {
        WhoopDI.removeAllDependencies()
    }
    
    func test_inject() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = WhoopDI.inject("C_Factory", "param")
        XCTAssertTrue(dependency is DependencyC)
    }
    
    func test_inject_generic_integer() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: GenericDependency<Int> = WhoopDI.inject()
        XCTAssertEqual(42, dependency.value)
    }
    
    func test_inject_generic_string() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: GenericDependency<String> = WhoopDI.inject()
        XCTAssertEqual("string", dependency.value)
    }
    
    func test_inject_localDefinition() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = WhoopDI.inject("C_Factory") { module in
            // Typically you'd override or provide a transient dependency. I'm using the top level dependency here
            // for the sake of simplicity.
            module.factory(name: "C_Factory") { DependencyA() as Dependency }
        }
        XCTAssertTrue(dependency is DependencyA)
    }
    
    func test_inject_localDefinition_noOverride() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = WhoopDI.inject("C_Factory", params: "params") { _ in }
        XCTAssertTrue(dependency is DependencyC)
    }
    
    func test_inject_localDefinition_withParams() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = WhoopDI.inject("C_Factory", params: "params") { module in
            module.factoryWithParams(name: "C_Factory") { params in DependencyB(params) as Dependency }
        }
        XCTAssertTrue(dependency is DependencyB)
    }
    
    func test_validation_fails_barParams() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let validator = WhoopDIValidator()
        var failed = false
        validator.validate { error in failed = true }
        XCTAssertTrue(failed)
    }
    
    func test_validation_fails_missingDependencies() {
        WhoopDI.registerModules(modules: [BadTestModule()])
        let validator = WhoopDIValidator()
        var failed = false
        validator.validate { error in
            let expectedKey = ServiceKey(Dependency.self, name: "A_Factory")
            let expectedError = DependencyError.missingDependecy(expectedKey)
            XCTAssertEqual(expectedError, error as! DependencyError)
            failed = true
        }
        XCTAssertTrue(failed)
    }
    
    func test_validation_fails_nilFactoryDependency() {
        WhoopDI.registerModules(modules: [NilFactoryModule()])
        let validator = WhoopDIValidator()
        var failed = false
        validator.validate { error in
            let expectedKey = ServiceKey(Optional<Dependency>.self)
            let expectedError = DependencyError.nilDependency(expectedKey)
            XCTAssertEqual(expectedError, error as! DependencyError)
            failed = true
        }
        XCTAssertTrue(failed)
    }
    
    func test_validation_fails_nilSingletonDependency() {
        WhoopDI.registerModules(modules: [NilSingletonModule()])
        let validator = WhoopDIValidator()
        var failed = false
        validator.validate { error in
            let expectedKey = ServiceKey(Optional<Dependency>.self)
            let expectedError = DependencyError.nilDependency(expectedKey)
            XCTAssertEqual(expectedError, error as! DependencyError)
            failed = true
        }
        XCTAssertTrue(failed)
    }
    
    func test_validation_succeeds() {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let validator = WhoopDIValidator()
        validator.addParams("param", forType: Dependency.self, andName: "B_Factory")
        validator.addParams("param", forType: Dependency.self, andName: "B_Single")
        validator.addParams("param", forType: DependencyB.self)
        validator.addParams("param", forType: DependencyC.self)
        validator.addParams("param", forType: Dependency.self, andName: "C_Factory")
        
        validator.validate { error in
            XCTFail("DI failed with error: \(error)")
        }
    }

    func test_injecting() {
        WhoopDI.registerModules(modules: [FakeTestModuleForInjecting()])
        let testInjecting: TestInjectingThing = WhoopDI.inject()
        XCTAssertEqual(testInjecting, TestInjectingThing(name: 1))
    }
}
