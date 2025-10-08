import Testing
@testable import WhoopDIKit
import Foundation

// Test accumulation keys
struct StringAccumulationKey: AccumulationKey {
    typealias FinalValue = [String]
    typealias AccumulatedValue = String

    static var initialValue: [String] { [] }

    static func accumulate(current: [String], next: String) -> [String] {
        current + [next]
    }
}

struct IntSumAccumulationKey: AccumulationKey {
    typealias FinalValue = Int
    typealias AccumulatedValue = Int

    static var initialValue: Int { 0 }

    static func accumulate(current: Int, next: Int) -> Int {
        current + next
    }
}

struct AccumulationTests {

    // MARK: - Single Value Accumulation Tests

    @Test
    func testSingleFactoryAccumulation() {
        let container = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Hello"
            }
        }

        let result: [String] = container.inject()
        #expect(result == ["Hello"])
    }

    @Test
    func testSingleSingletonAccumulation() {
        let container = Container { module in
            module.accumulateSingleton(for: StringAccumulationKey.self) {
                "World"
            }
        }

        let result: [String] = container.inject()
        #expect(result == ["World"])
    }

    @Test
    func testMultipleAccumulationsViaChildContainers() throws {
        let container = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "First"
            }
        }

        let child1 = container.createChild { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Second"
            }
        }

        let child2 = child1.createChild { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Third"
            }
        }

        let result: [String] = child2.inject()
        #expect(result == ["First", "Second", "Third"])
    }

    // MARK: - Parent-Child Accumulation Tests

    @Test
    func testParentChildAccumulation() throws {
        let parent = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Parent"
            }
        }

        let child = parent.createChild { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Child"
            }
        }

        let result: [String] = child.inject()
        #expect(result == ["Parent", "Child"])
    }

    @Test
    func testMultipleLevelAccumulation() throws {
        let grandparent = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Grandparent"
            }
        }

        let parent = grandparent.createChild { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Parent"
            }
        }

        let child = parent.createChild { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Child"
            }
        }

        let result: [String] = child.inject()
        #expect(result == ["Grandparent", "Parent", "Child"])
    }

    @Test
    func testParentOnlyAccumulation() throws {
        let parent = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Parent"
            }
        }

        let child = parent.createChild()

        // Child should inherit parent's accumulation
        let result: [String] = child.inject()
        #expect(result == ["Parent"])
    }

    // MARK: - Sibling Container Tests

    @Test
    func testSiblingContainerAccumulations() throws {
        let parent = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Parent"
            }
        }

        let sibling1 = parent.createChild { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Sibling1"
            }
        }

        let sibling2 = parent.createChild { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Sibling2"
            }
        }

        // Each sibling should have parent + their own value
        let result1: [String] = sibling1.inject()
        #expect(result1 == ["Parent", "Sibling1"])

        let result2: [String] = sibling2.inject()
        #expect(result2 == ["Parent", "Sibling2"])
    }

    @Test
    func testSiblingInModuleAccumulations() throws {
        let parent = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Parent"
            }
        }

        let child = parent.createChild { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Sibling1"
            }

            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Sibling2"
            }
        }

        // Each value should be accumulated
        let result: [String] = child.inject()
        #expect(result == ["Parent", "Sibling1", "Sibling2"])

    }

    // MARK: - Mixed Factory and Singleton Tests
    @Test
    func testMixedFactoryAndSingleton() throws {
        let container = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Factory"
            }
        }

        let child = container.createChild { module in
            module.accumulateSingleton(for: StringAccumulationKey.self) {
                "Singleton"
            }
        }

        let result: [String] = child.inject()
        #expect(result == ["Factory", "Singleton"])
    }

    // MARK: - Different Accumulation Key Tests

    @Test
    func testDifferentAccumulationKeys() throws {
        let container = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Hello"
            }
            module.accumulateFactory(for: IntSumAccumulationKey.self) {
                10
            }
        }

        let child = container.createChild { module in
            module.accumulateFactory(for: IntSumAccumulationKey.self) {
                20
            }
        }

        let stringResult: [String] = container.inject()
        #expect(stringResult == ["Hello"])

        let intResult: Int = child.inject()
        #expect(intResult == 30)
    }

     // MARK: - Singleton Caching Tests

    @Test
    func testSingletonAccumulationIsCached() throws {
        var callCount = 0

        let container = Container { module in
            module.accumulateSingleton(for: IntSumAccumulationKey.self) {
                callCount += 1
                return 10
            }
        }

        let result1: Int = container.inject()
        let result2: Int = container.inject()

        #expect(result1 == 10)
        #expect(result2 == 10)
        #expect(callCount == 1, "Singleton accumulation should only be called once")
    }

    @Test
    func testFactoryAccumulationIsNotCached() throws {
        var callCount = 0

        let container = Container { module in
            module.accumulateFactory(for: IntSumAccumulationKey.self) {
                callCount += 1
                return 10
            }
        }

        let result1: Int = container.inject()
        let result2: Int = container.inject()

        #expect(result1 == 10)
        #expect(result2 == 10)
        #expect(callCount == 2, "Factory accumulation should be called each time")
    }

    // MARK: - Empty Accumulation Tests

    @Test
    func testEmptyAccumulationReturnsDefaultWhenNoDefinition() throws {
        // When there's no accumulation definition, inject should fail with missing dependency
        // This is expected behavior - you need at least one accumulation definition
        let container = Container()

        #expect(throws: DependencyError.self) {
            let _: [String] = try container.get()
        }
    }

    @Test
    func testSubDependencies() throws {
        let container = Container(modules: [
            Dependency1(),
            Dependency2()
        ],
                                  parent: nil)
        let value: Int = container.inject()
        #expect(value == 4)
    }

    // MARK: - Named Accumulation Tests

    @Test
    func testNamedFactoryAccumulation() throws {
        let container = Container { module in
            module.accumulateFactory(name: "list1", for: StringAccumulationKey.self) {
                "First"
            }
            module.accumulateFactory(name: "list2", for: StringAccumulationKey.self) {
                "Alpha"
            }
        }

        let result1: [String] = container.inject("list1")
        #expect(result1 == ["First"])

        let result2: [String] = container.inject("list2")
        #expect(result2 == ["Alpha"])
    }

    @Test
    func testNamedSingletonAccumulation() throws {
        let container = Container { module in
            module.accumulateSingleton(name: "list1", for: StringAccumulationKey.self) {
                "First"
            }
            module.accumulateSingleton(name: "list2", for: StringAccumulationKey.self) {
                "Alpha"
            }
        }

        let result1: [String] = container.inject("list1")
        #expect(result1 == ["First"])

        let result2: [String] = container.inject("list2")
        #expect(result2 == ["Alpha"])
    }

    @Test
    func testNamedAccumulationWithParentChild() throws {
        let parent = Container { module in
            module.accumulateFactory(name: "list1", for: StringAccumulationKey.self) {
                "Parent"
            }
        }

        let child = parent.createChild { module in
            module.accumulateFactory(name: "list1", for: StringAccumulationKey.self) {
                "Child"
            }
        }

        let result: [String] = child.inject("list1")
        #expect(result == ["Parent", "Child"])
    }

    @Test
    func testNamedAndUnnamedAccumulationsAreSeparate() throws {
        let container = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Unnamed"
            }
            module.accumulateFactory(name: "named", for: StringAccumulationKey.self) {
                "Named"
            }
        }

        let unnamedResult: [String] = container.inject()
        #expect(unnamedResult == ["Unnamed"])

        let namedResult: [String] = container.inject("named")
        #expect(namedResult == ["Named"])
    }

    @Test
    func testNamedSingletonAccumulationIsCached() throws {
        var callCount1 = 0
        var callCount2 = 0

        let container = Container { module in
            module.accumulateSingleton(name: "sum1", for: IntSumAccumulationKey.self) {
                callCount1 += 1
                return 10
            }
            module.accumulateSingleton(name: "sum2", for: IntSumAccumulationKey.self) {
                callCount2 += 1
                return 20
            }
        }

        let result1a: Int = container.inject("sum1")
        let result1b: Int = container.inject("sum1")
        let result2a: Int = container.inject("sum2")
        let result2b: Int = container.inject("sum2")

        #expect(result1a == 10)
        #expect(result1b == 10)
        #expect(result2a == 20)
        #expect(result2b == 20)
        #expect(callCount1 == 1, "Named singleton accumulation should only be called once")
        #expect(callCount2 == 1, "Named singleton accumulation should only be called once")
    }

    @Test
    func testSingletonAccumulationIsCachedForKey() throws {
        let container = Container { module in
            module.accumulateSingleton(for: AccumulationCountKey.self) {
                2
            }
        }

        let child = container.createChild { module in
            module.accumulateSingleton(for: AccumulationCountKey.self) {
                3
            }
        }

        let acc: Int = child.inject()
        let acc2: Int = child.inject()
        #expect(acc == 5)
        #expect(acc2 == 5)
        #expect(AccumulationCountKey.count == 2) // there are 2 dependencies, but only called once
    }

    @Test
    func testItWorksWithSubDependency() throws {
        let container = Container { module in
            module.factory {
                let intValue: Int = try module.get()
                return "\(intValue)"
            }
        }

        let child = container.createChild { module in
            module.accumulateSingleton(for: IntSumAccumulationKey.self) {
                3
            }
        }

        let newValue: String = child.inject()
        #expect(newValue == "3")

    }

    // MARK: - Stress Test
    @Test
    func testSubDependencies_many() throws {
        let upperLimit  = Int(pow(2.0, 14.0))
        let modules = (0..<upperLimit).map { _ in
            ManyDependency()
        }
        let container = Container(modules: modules, parent: nil)
        let value: Int = container.inject()
        #expect(value == upperLimit)
    }
}

class Dependency1: DependencyModule {
    override var moduleDependencies: [DependencyModule] {
        [SubDependency1()]
    }

    override func defineDependencies() {
        accumulateFactory(for: IntSumAccumulationKey.self) {
            1
        }
    }
}

class SubDependency1: DependencyModule {
    override func defineDependencies() {
        accumulateFactory(for: IntSumAccumulationKey.self) {
            1
        }
    }
}

class Dependency2: DependencyModule {
    override var moduleDependencies: [DependencyModule] {
        [SubDependency2()]
    }

    override func defineDependencies() {
        accumulateFactory(for: IntSumAccumulationKey.self) {
            1
        }
    }
}

class SubDependency2: DependencyModule {
    override func defineDependencies() {
        accumulateFactory(for: IntSumAccumulationKey.self) {
            1
        }
    }
}

class ManyDependency: DependencyModule {
    override var serviceKey: ServiceKey {
        ServiceKey(type(of: self), name: UUID.init().uuidString)
    }

    override func defineDependencies() {
        accumulateFactory(for: IntSumAccumulationKey.self) {
            1
        }
    }
}

class AccumulationCountKey: AccumulationKey {
    static nonisolated(unsafe) var count: Int = 0

    static let initialValue: Int = 0

    static func accumulate(current: Int, next: Int) -> Int {
        count += 1
        return current + next
    }
}
