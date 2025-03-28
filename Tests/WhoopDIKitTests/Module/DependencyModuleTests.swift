import Foundation
import Testing
@testable import WhoopDIKit

@MainActor
class DependencyModuleTests {
    private let serviceKey = ServiceKey(String.self, name: "name")
    private let serviceDict = ServiceDictionary<DependencyDefinition>()
    
    private let module = DependencyModule()
    
    @Test
    func defineDependencies_defaultDoesNothing() {
        module.defineDependencies()
        module.addToServiceDictionary(serviceDict: serviceDict)
        #expect(serviceDict.allKeys().isEmpty)
    }
    
    @Test
    func factory() {
        module.factory(name: "name") { "dependency" }
        module.addToServiceDictionary(serviceDict: serviceDict)
        
        let defintion = serviceDict[serviceKey]
        #expect(defintion is FactoryDefinition)
    }

    @Test
    func get_missingContainer_fallsBackOnAppContainer() throws {
        WhoopDI.setup(modules: [GoodTestModule()])
        
        let dependencyC: DependencyC = try module.get(params: "params")
        #expect(dependencyC != nil)
        
        WhoopDI.removeAllDependencies()
    }

    @Test
    func factoryWithParams() {
        module.factoryWithParams(name: "name") { (_: Any) in "dependency" }
        module.addToServiceDictionary(serviceDict: serviceDict)
        
        let defintion = serviceDict[serviceKey]
        #expect(defintion is FactoryDefinition)
    }
    
    @Test
    func singleton() {
        module.singleton(name: "name") { "dependency" }
        module.addToServiceDictionary(serviceDict: serviceDict)
        
        let defintion = serviceDict[serviceKey]
        #expect(defintion is SingletonDefinition)
    }
    
    @Test
    func singletonWithParams() {
        module.singletonWithParams(name: "name") { (_: Any) in "dependency" }
        module.addToServiceDictionary(serviceDict: serviceDict)
        
        let defintion = serviceDict[serviceKey]
        #expect(defintion is SingletonDefinition)
    }
    
    @Test
    func serviceKey_Returns_Subclass_Type() {
        let testModule = TestDependencyModule(testModuleDependencies: [])
        #expect(testModule.serviceKey == ServiceKey(type(of: TestDependencyModule())))
    }
    
    @Test
    func setMultipleModuleDependencies() {
        let moduleA = DependencyModule()
        let moduleB = DependencyModule()
        let moduleC = DependencyModule()
        let moduleD = DependencyModule()
        
        let module = TestDependencyModule(testModuleDependencies: [moduleD, moduleC, moduleB, moduleA])
        #expect(module.moduleDependencies == [moduleD, moduleC, moduleB, moduleA])
    }
    
    @Test
    func setSingleModuleDependency() {
        let moduleA = DependencyModule()
        
        let module = TestDependencyModule(testModuleDependencies: [moduleA])
        #expect(module.moduleDependencies == [moduleA])
    }
    
    @Test
    func setNoModuleDependencies() {
        let module = TestDependencyModule()
        #expect(module.moduleDependencies.isEmpty)
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
