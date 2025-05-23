import Foundation
@testable import WhoopDIKit

class GoodTestModule: DependencyModule {
    override func defineDependencies() {
        factory { DependencyA() }
        singleton { DependencyD() }
        factory(name: "A_Factory") { DependencyA() as Dependency }
        singleton(name: "A_Single") { DependencyA() as Dependency }

        factory { GenericDependency("string") }
        factory { GenericDependency(42) }

        factoryWithParams(name: "B_Factory") { params in DependencyB(params) as Dependency }
        factoryWithParams { params in DependencyB(params) }
        singletonWithParams(name: "B_Single") { params in DependencyB(params) as Dependency }

        factoryWithParams { params in
            DependencyC(proto: try self.get("A_Factory"),
                        concrete: try self.get(params: params))
        }
        factoryWithParams(name: "C_Factory") { params in
            DependencyC(proto: try self.get("A_Factory"),
                        concrete: try self.get(params: params)) as Dependency
        }
    }
}

class OverrideModule: DependencyModule {
    override func defineDependencies() {
        factory(name: "C_Factory") {
            DependencyA() as Dependency
        }

        factory(name: "integer") { 1 }
    }
}

class BadTestModule: DependencyModule {
    override func defineDependencies() {
        factoryWithParams { params in
            DependencyC(proto: try self.get("A_Factory"),
                        concrete: try self.get(params: params))
        }
    }
}

class NilFactoryModule: DependencyModule {
    override func defineDependencies() {
        factory { nil as Dependency? }
    }
}

class NilSingletonModule: DependencyModule {
    override func defineDependencies() {
        singleton { nil as Dependency? }
    }
}

protocol Dependency { }

struct DependencyA: Dependency, Equatable { }

class DependencyB: Dependency {
    private let param: String

    internal init(_ param: String) {
        self.param = param
    }
}

class DependencyC: Dependency {
    private let proto: Dependency
    private let concrete: DependencyB

    internal init(proto: Dependency, concrete: DependencyB) {
        self.proto = proto
        self.concrete = concrete
    }
}

class DependencyD: Dependency { }

struct GenericDependency<T>: Dependency {
    let value: T

    init(_ value: T) {
        self.value = value
    }
}

class FakeTestModuleForInjecting: DependencyModule {
    override func defineDependencies() {
        factory { DependencyA() }
        factory(name: "FakeName") { 1 }
        factory(name: "VariableFakeName") { "variable" }
        factory(name: "GlobalVariableFakeName") { "global" }
    }
}

class ChildTestModule: DependencyModule {
    override func defineDependencies() {
        factory(name: "a") { DependencyA() as Dependency }
        factory { DependencyB("") }
    }
}

class ParentTestModule: DependencyModule {
    override var moduleDependencies: [DependencyModule] {
        [ChildTestModule()]
    }
    
    override func defineDependencies() {
        factory { DependencyC(proto: try self.get("a"), concrete: try self.get()) as Dependency }
    }
}

@Injectable
struct InjectableWithDependency: Equatable {
    private let dependency: DependencyA
}

struct InjectableTestNames {
    static let variableFakeName = "VariableFakeName"
}

let globalVariableFakeName: String = "GlobalVariableFakeName"

@Injectable
struct InjectableWithNamedDependency: Equatable {
    @InjectableName(name: "FakeName")
    let name: Int

    @InjectableName(name: InjectableTestNames.variableFakeName)
    let nameFromVariable: String

    @InjectableName(name: globalVariableFakeName)
    let globalVariableName: String
}

