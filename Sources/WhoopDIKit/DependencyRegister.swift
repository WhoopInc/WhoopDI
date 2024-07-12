@MainActor
public protocol DependencyRegister {
    static func removeAllDependencies()
    static func registerModules(modules: [DependencyModule])
}
