public protocol ModuleList {
    var modules: [DependencyModule] { get }
}

public final class EmptyModuleList: ModuleList {
    public var modules: [DependencyModule] { [] }
}
