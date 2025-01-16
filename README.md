# WhoopDI

WhoopDI is a simple dependency injection package for Swift.

# Installation

WhoopDI is available through [Swift Package Manager](https://swift.org/package-manager/). 

To install it, simply add the following line to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/WhoopInc/WhoopDI.git", from: "0.0.3.9")
]
```

Then include it in your target's dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["WhoopDIKit"]),
]
```

# Usage

There are a few simple steps to setup WhoopDI in your project:
1. Define dependency modules which defined your dependencies.
2. Register your dependencies with WhoopDI.
3. Inject your top level dependencies.

## Dependency Modules

You can define your dependencies in a module by creating a class that conforms to `DependencyModule`. This class should define a `registerDependencies` method which will be called by WhoopDI to register your dependencies.

```swift
final class MyModule: DependencyModule {
    override func defineDependencies() {
        factory { MyConcreteObject() }
        factory { try MyObject(dependency: self.get()) as MyProtocol }
        factory(named: "MyNamedObject") { MyNamedObject() as MyNamedProtocol }
        singleton { try MySingletonObject(dependency: self.get()) }
    }
}
```

A few interesting things to note in the above snippet:
- `factory` is used to register a factory dependency. This means that every time you request this dependency from WhoopDI, a new instance will be created.
- `singleton` is used to register a singleton dependency. This means that only one instance of this dependency will be created and returned every time it is requested.
- `named` is used to register a dependency with a specific name. This is useful when you have multiple dependencies of the same type.
- `get` is used to retrieve a dependency from the container. This is useful when you need to pass a dependency to another dependency. Note this can throw in testing mode if the dependency is not registered, so a `try` is required.

### Injectable Macro

For simple, non-singleton dependencies you can leverage the `@Injectable` macro to automatically create a factory for you.

```swift
class FakeTestModuleForInjecting: DependencyModule {
    override func defineDependencies() {
        factory(name: "Important") { 1 }
    }
}

// ...

@Injectable
struct InjectableWithNamedDependency: Equatable {
    @InjectableName(name: "Important")
    let anImportantNumber: Int
}

let dependency: InjectableWithNamedDependency = container.inject()
```

In the above example, we do not need to define a factory for `InjectableWithNamedDependency`. Since this is decorated with the Injectable macro WhoopDI will automatically create it and provide it's dependencies when it is requested via an `inject` or `get` method.

If you need to provide a named dependency, you can use the `@InjectableName` macro to specify the name of the dependency you want to inject.


## Register Dependencies

To register modules with WhoopDI, you can use the `registerModules` method of WhoopDI. This method takes a list of modules to register:

```swift
WhoopDI.registerModules([MyModule()])
```

## Inject Dependencies

The simplest way to inject a dependency is to use the `inject` method of WhoopDI.

```swift
let myFeature: MyFeature = WhoopDI.inject()
let myNamedFeature: MyNamedFeature = WhoopDI.inject("named")
```

These inject methods will piece together the dependencies you have registered and return the top level dependency you are requesting. A few notes here:
- Type lookup happens via generics, so WhoopDI must be able to to infer the type you are requesting.
- If you have multiple dependencies of the same type, you can use the `named` parameter to specify which dependency you want.
- If the dependency you are requesting is not registered, WhoopDI will fill throw a fatal error (at runtime).
- You should inject only your top level dependencies (e.g. view controllers, services, etc.). Most of your code should be unaware of WhoopDI.
    - In other words, you should not invoke `WhoopDI.inject` in your lower level dependencies. They should be provided in a module, then injected into your top level dependencies.

### Local Module Inject

Sometimes you have local variables which you want to pass into the dependency graph. This can be achieved by using the `inject` with closure method of WhoopDI.`

```swift
let theAnswer = 42
WhoopDI.inject { module in
    module.factory(name: "answer") { theAnswer }
}
```

The above introduces the local variable into the dependency graph. It can then be a dependency in an existing module, or you can provide additional factory definitions which depend upon it in the closure.

# Testing

WhoopDI is designed to be easy to test. You can leverage the `WhoopDIValidator` to validate your modules and ensure that all needed dependencies are provided to the dependency graph.

```swift
class MyDITests: XCTestCase {
    override func tearDown() async throws {
        await WhoopDI.removeAllDependencies()
    }
    

    func test_allDependenciesProvided() {
        WhoopDI.registerModules(modules: [MyModule()])
        
        let validator = WhoopDIValidator()
        validator.validate { error in
            XCTFail("DI failed with error: \(error)")
        }
    }
}
```

# Building

To build the project, you can use the following command:

```bash
swift build
```

To run tests locally, you can use the following command:

```bash
swift test
```

You can also open the project folder in Xcode and run the tests from there.