import XCTest
@testable import WhoopDIKit

class ContainerTests: XCTestCase {
    private let container = Container()

    func test_inject() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory", "param")
        XCTAssertTrue(dependency is DependencyC)
    }

    func test_inject_generic_integer() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: GenericDependency<Int> = container.inject()
        XCTAssertEqual(42, dependency.value)
    }

    func test_inject_generic_string() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: GenericDependency<String> = container.inject()
        XCTAssertEqual("string", dependency.value)
    }

    func test_inject_localDefinition() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory") { module in
            // Typically you'd override or provide a transient dependency. I'm using the top level dependency here
            // for the sake of simplicity.
            module.factory(name: "C_Factory") { DependencyA() as Dependency }
        }
        XCTAssertTrue(dependency is DependencyA)
    }

    func test_inject_localDefinition_noOverride() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory", params: "params") { _ in }
        XCTAssertTrue(dependency is DependencyC)
    }

    func test_inject_localDefinition_withParams() {
        container.registerModules(modules: [GoodTestModule()])
        let dependency: Dependency = container.inject("C_Factory", params: "params") { module in
            module.factoryWithParams(name: "C_Factory") { params in DependencyB(params) as Dependency }
        }
        XCTAssertTrue(dependency is DependencyB)
    }
    
    func test_injectableWithDependency() throws {
        container.registerModules(modules: [FakeTestModuleForInjecting()])
        let testInjecting: InjectableWithDependency = container.inject()
        XCTAssertEqual(testInjecting, InjectableWithDependency(dependency: DependencyA()))
    }

    func test_injectableWithNamedDependency() throws {
        container.registerModules(modules: [FakeTestModuleForInjecting()])
        let testInjecting: InjectableWithNamedDependency = container.inject()
        XCTAssertEqual(testInjecting, InjectableWithNamedDependency(name: 1))
    }
}
