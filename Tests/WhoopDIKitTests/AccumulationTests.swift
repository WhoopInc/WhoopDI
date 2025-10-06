import XCTest
@testable import WhoopDIKit

// Test accumulation keys
struct StringAccumulationKey: AccumulationKey {
    typealias FinalValue = [String]
    typealias AccumulatedValue = String

    static var defaultValue: [String] { [] }

    static func accumulate(current: [String], next: String) -> [String] {
        current + [next]
    }
}

struct IntSumAccumulationKey: AccumulationKey {
    typealias FinalValue = Int
    typealias AccumulatedValue = Int

    static var defaultValue: Int { 0 }

    static func accumulate(current: Int, next: Int) -> Int {
        current + next
    }
}

final class AccumulationTests: XCTestCase {

    // MARK: - Single Value Accumulation Tests

    func testSingleFactoryAccumulation() throws {
        let container = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Hello"
            }
        }

        let result: [String] = container.inject()
        XCTAssertEqual(result, ["Hello"])
    }

    func testSingleSingletonAccumulation() throws {
        let container = Container { module in
            module.accumulateSingleton(for: StringAccumulationKey.self) {
                "World"
            }
        }

        let result: [String] = container.inject()
        XCTAssertEqual(result, ["World"])
    }

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
        XCTAssertEqual(result, ["First", "Second", "Third"])
    }

    // MARK: - Parent-Child Accumulation Tests

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
        XCTAssertEqual(result, ["Parent", "Child"])
    }

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
        XCTAssertEqual(result, ["Grandparent", "Parent", "Child"])
    }

    func testParentOnlyAccumulation() throws {
        let parent = Container { module in
            module.accumulateFactory(for: StringAccumulationKey.self) {
                "Parent"
            }
        }

        let child = parent.createChild()

        // Child should inherit parent's accumulation
        let result: [String] = child.inject()
        XCTAssertEqual(result, ["Parent"])
    }

    // MARK: - Sibling Container Tests

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
        XCTAssertEqual(result1, ["Parent", "Sibling1"])

        let result2: [String] = sibling2.inject()
        XCTAssertEqual(result2, ["Parent", "Sibling2"])
    }

    // MARK: - Mixed Factory and Singleton Tests

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
        XCTAssertEqual(result, ["Factory", "Singleton"])
    }

    // MARK: - Different Accumulation Key Tests

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
        XCTAssertEqual(stringResult, ["Hello"])

        let intResult: Int = child.inject()
        XCTAssertEqual(intResult, 30)
    }

    // MARK: - Parameters Tests

    func testAccumulationWithParams() throws {
        struct Config {
            let prefix: String
        }

        let container = Container { module in
            module.accumulateFactoryWithParams(for: StringAccumulationKey.self) { (config: Config) in
                "\(config.prefix)-First"
            }
        }

        let child = container.createChild { module in
            module.accumulateFactoryWithParams(for: StringAccumulationKey.self) { (config: Config) in
                "\(config.prefix)-Second"
            }
        }

        let result: [String] = child.inject(nil, Config(prefix: "Test"))
        XCTAssertEqual(result, ["Test-First", "Test-Second"])
    }

    // MARK: - Singleton Caching Tests

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

        XCTAssertEqual(result1, 10)
        XCTAssertEqual(result2, 10)
        XCTAssertEqual(callCount, 1, "Singleton accumulation should only be called once")
    }

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

        XCTAssertEqual(result1, 10)
        XCTAssertEqual(result2, 10)
        XCTAssertEqual(callCount, 2, "Factory accumulation should be called each time")
    }

    // MARK: - Empty Accumulation Tests

    func testEmptyAccumulationReturnsDefaultWhenNoDefinition() throws {
        // When there's no accumulation definition, inject should fail with missing dependency
        // This is expected behavior - you need at least one accumulation definition
        let container = Container()

        XCTAssertThrowsError(try {
            let _: [String] = try container.get()
        }()) { error in
            XCTAssertTrue(error is DependencyError)
        }
    }
}
