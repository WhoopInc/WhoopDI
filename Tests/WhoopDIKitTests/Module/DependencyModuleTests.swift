import Foundation
import XCTest
@testable import WhoopDIKit

class DependencyModuleTests: XCTestCase {
    private let serviceKey = ServiceKey(String.self, name: "name")
    private let serviceDict = ServiceDictionary<DependencyDefinition>()
    
    private let module = DependencyModule()
    
    func test_factory() {
        module.factory(name: "name") { "dependency" }
        module.addToServiceDictionary(serviceDict: serviceDict)
        
        let defintion = serviceDict[serviceKey]
        XCTAssertTrue(defintion is FactoryDefinition)
    }

    func test_get_missingContainer_fallsBackOnAppContainer() throws {
        WhoopDI.registerModules(modules: [GoodTestModule()])
        let dependencyC: DependencyC = try module.get(params: "params")
        XCTAssertNotNil(dependencyC)
        WhoopDI.removeAllDependencies()
    }

    func test_factoryWithParams() {
        module.factoryWithParams(name: "name") { (_: Any) in "dependency" }
        module.addToServiceDictionary(serviceDict: serviceDict)
        
        let defintion = serviceDict[serviceKey]
        XCTAssertTrue(defintion is FactoryDefinition)
    }
    
    func test_singleton() {
        module.singleton(name: "name") { "dependency" }
        module.addToServiceDictionary(serviceDict: serviceDict)
        
        let defintion = serviceDict[serviceKey]
        XCTAssertTrue(defintion is SingletonDefinition)
    }
    
    func test_singletonWithParams() {
        module.singletonWithParams(name: "name") { (_: Any) in "dependency" }
        module.addToServiceDictionary(serviceDict: serviceDict)
        
        let defintion = serviceDict[serviceKey]
        XCTAssertTrue(defintion is SingletonDefinition)
    }
    
    func test_serviceKey_Returns_Subclass_Type() {
        let testModule = TestDependencyModule(testModuleDependencies: [])
        XCTAssertEqual(testModule.serviceKey, ServiceKey(type(of: TestDependencyModule())))
    }
    
    func test_setMultipleModuleDependencies() {
        let moduleA = DependencyModule()
        let moduleB = DependencyModule()
        let moduleC = DependencyModule()
        let moduleD = DependencyModule()
        
        let module = TestDependencyModule(testModuleDependencies: [moduleD, moduleC, moduleB, moduleA])
        XCTAssertEqual(module.moduleDependencies, [moduleD, moduleC, moduleB, moduleA])
    }
    
    func test_setSingleModuleDependency() {
        let moduleA = DependencyModule()
        
        let module = TestDependencyModule(testModuleDependencies: [moduleA])
        XCTAssertEqual(module.moduleDependencies, [moduleA])
    }
    
    func test_setNoModuleDependencies() {
        let module = TestDependencyModule()
        XCTAssertEqual(module.moduleDependencies, [])
    }
}

final fileprivate class TestDependencyModule: DependencyModule {
    private let testModuleDependencies: [DependencyModule]
    
    init(testModuleDependencies: [DependencyModule] = []) {
        self.testModuleDependencies = testModuleDependencies
        super.init()
    }
    
    override var moduleDependencies: [DependencyModule] {
        testModuleDependencies
    }
}
