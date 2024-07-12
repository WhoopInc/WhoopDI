import Foundation

/// Performs a depth first, post ordered search of the given module's dependency tree and flattens the tree into a list of modules
/// in which the lowest level modules are ordered first.
@MainActor
public final class DependencyTree {
    
    private let dependencyModule: [DependencyModule]
    
    public init(dependencyModule: [DependencyModule]) {
        self.dependencyModule = dependencyModule
        dependencyModule.forEach { module in
            self.traverseTree(for: module)
        }
    }
    
    private var moduleSet: Set<ServiceKey> = []
    private var allModules: [DependencyModule] = []
    
    /// Recursively traverse a single `dependencyModule` dependency tree.
    /// Populates `allModules` with a collection of unique dependency modules to avoid duplication and dependency loops. 
    /// 
    /// - Parameter module: a dependency module
    private func traverseTree(for module: DependencyModule) {
        if moduleSet.contains(module.serviceKey) { return }
        moduleSet.insert(module.serviceKey)
        
        module.moduleDependencies.forEach { 
            traverseTree(for: $0)
        }
        
        allModules.append(module)
    }
    
    /// Gets a list of dependent modules for the given module
    public var modules: [DependencyModule] { 
        get {
            return allModules
        }
    }
}
