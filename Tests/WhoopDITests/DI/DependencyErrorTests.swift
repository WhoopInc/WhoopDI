import XCTest
@testable import WhoopDI

class DependencyErrorTests: XCTestCase {
    private let serviceKey = ServiceKey(String.self)
    private let serviceKeyWithName = ServiceKey(String.self, name: "name")
    
    func test_description_badParams_noServiceKeyName() {
        let expected = "Bad parameters provided for String with name: <no name>"
        let error = DependencyError.badParams(serviceKey)
        XCTAssertEqual(expected, error.description)
    }
    
    func test_description_badParams_withServiceKeyName() {
        let expected = "Bad parameters provided for String with name: name"
        let error = DependencyError.badParams(serviceKeyWithName)
        XCTAssertEqual(expected, error.description)
    }
    
    func test_description_missingDependecy_noServiceKeyName() {
        let expected = "Missing dependency for String with name: <no name>"
        let error = DependencyError.missingDependecy(serviceKey)
        XCTAssertEqual(expected, error.description)
    }
    
    func test_description_missingDependecy_withServiceKeyName() {
        let expected = "Missing dependency for String with name: name"
        let error = DependencyError.missingDependecy(serviceKeyWithName)
        XCTAssertEqual(expected, error.description)
    }
    
    func test_description_nilDependecy_noServiceKeyName() {
        let expected = "Nil dependency for String with name: <no name>"
        let error = DependencyError.nilDependency(serviceKey)
        XCTAssertEqual(expected, error.description)
    }
    
    func test_description_nilDependecy_withServiceKeyName() {
        let expected = "Nil dependency for String with name: name"
        let error = DependencyError.nilDependency(serviceKeyWithName)
        XCTAssertEqual(expected, error.description)
    }
}
