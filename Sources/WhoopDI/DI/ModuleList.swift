public protocol ModuleList {
    var modules: [DependencyModule] { get }
}

public class EmptyModuleList: ModuleList {
    public var modules: [DependencyModule] { [] }
}
