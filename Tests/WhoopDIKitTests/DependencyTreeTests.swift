import XCTest
@testable import WhoopDIKit

final class DependencyTreeTests: XCTestCase {

    override func tearDown() async throws {
        await WhoopDI.removeAllDependencies()
    }
    
    @MainActor
    func testDepthFirstSearch_SingleList() {
        let moduleD = module("D")
        let moduleC = module("C", dependentModules: [moduleD])
        let moduleB = module("B", dependentModules: [moduleC])
        let moduleA = module("A", dependentModules: [moduleB])
        
        let tree = DependencyTree(dependencyModule: [moduleA])
        XCTAssertEqual([moduleD, moduleC, moduleB, moduleA], tree.modules)
    }
    
    @MainActor
    func testDepthFirstSearch_SingeList_FilterDuplicates() {
        let moduleDuplicate = module("C")
        let moduleC = module("C", dependentModules: [moduleDuplicate])
        let moduleB = module("B", dependentModules: [moduleC])
        let moduleA = module("A", dependentModules: [moduleB])
        
        let tree = DependencyTree(dependencyModule: [moduleA])
        XCTAssertEqual([moduleC, moduleB, moduleA], tree.modules)
    }
    
    @MainActor
    func testDepthFirstSearch_NoDependencyLoop() {
        var loopDependency: [DependencyModule] = []
        let moduleC = KeyedModule(key: "C", keyedModuleDependencies: loopDependency)
        let moduleB = module("B", dependentModules: [moduleC])
        let moduleA = module("A", dependentModules: [moduleB])
        loopDependency.append(moduleA)
        
        let tree = DependencyTree(dependencyModule: [moduleA])
        XCTAssertEqual([moduleC, moduleB, moduleA], tree.modules)
    }
    
    @MainActor
    func testDepthFirstSearch_OneTopLevelModule() {
        let modules = generateTree(rootKey: "A")
        
        let tree = DependencyTree(dependencyModule: modules)
        
        let keys = [
            "A-2-0",
            "A-2-1",
            "A-2-2",
            "A-1-0",
            "A-1-1",
            "A-1-2",
            "A-0-0",
            "A-0-1",
            "A-0-2" 
        ]
        
        XCTAssertEqual(keys, tree.modules.map { $0.serviceKey.name })
    }
    
    @MainActor
    func testDepthFirstSearch_MultipleTopLevelModules() {
        let modules = generateTree(rootKey: "A") + generateTree(rootKey: "B")
        
        let tree = DependencyTree(dependencyModule: modules)
        
        let keys = ["A", "B"].flatMap { key in
            return [
                "\(key)-2-0",
                "\(key)-2-1",
                "\(key)-2-2",
                "\(key)-1-0",
                "\(key)-1-1",
                "\(key)-1-2",
                "\(key)-0-0",
                "\(key)-0-1",
                "\(key)-0-2"
            ]
        }
        
        XCTAssertEqual(keys, tree.modules.map { $0.serviceKey.name })
    }
    
    @MainActor
    func testDepthFirstSearch_DuplicateTopLevelModules() {
        let modules = generateTree(rootKey: "A") + generateTree(rootKey: "A")
        
        let tree = DependencyTree(dependencyModule: modules)
        
        let keys = [
            "A-2-0",
            "A-2-1",
            "A-2-2",
            "A-1-0",
            "A-1-1",
            "A-1-2",
            "A-0-0",
            "A-0-1",
            "A-0-2"
        ]
        
        XCTAssertEqual(keys, tree.modules.map { $0.serviceKey.name })
    }
}

private extension DependencyTreeTests {
    @MainActor
    func generateTree(rootKey: String = "", depth: Int = 0) -> [KeyedModule] {
        if depth == 3 { return [] }
        
        return (0...2).compactMap { val in
            let key = "\(rootKey)-\(depth)-\(val)"
            let children = generateTree(rootKey: rootKey, depth: depth + 1)
            return module(key, dependentModules: children)
        }
    }
    
    @MainActor
    func module(_ name: String, dependentModules: [DependencyModule] = []) -> KeyedModule {
        KeyedModule(key: name, keyedModuleDependencies: dependentModules)
    }
}

fileprivate class KeyedModule: DependencyModule {
    private let key: String
    private let keyedModuleDependencies: [DependencyModule]

    init(key: String, keyedModuleDependencies: [DependencyModule]) {
        self.key = key
        self.keyedModuleDependencies = keyedModuleDependencies
        super.init()
    }
    
    override var serviceKey: ServiceKey {
        ServiceKey(Self.self, name: key)
    }
    
    override var moduleDependencies: [DependencyModule] {
        keyedModuleDependencies
    }
}
