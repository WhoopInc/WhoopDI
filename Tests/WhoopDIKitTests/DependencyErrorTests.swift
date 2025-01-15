import XCTest
@testable import WhoopDIKit

class DependencyErrorTests: XCTestCase {
    private let emptyDict = ServiceDictionary<DependencyDefinition>()
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
    
    func test_description_missingDependency_noServiceKeyName() {
        let error = DependencyError.createMissingDependencyError(missingDependency: serviceKey, serviceDict: emptyDict)
        let expected = """
        Missing dependency for String with name: <no name>
        Container has a total of 0 dependencies.
        """
        XCTAssertEqual(expected, error.description)
    }
    
    func test_description_missingDependency_withServiceKeyName() {
        let error = DependencyError.createMissingDependencyError(missingDependency: serviceKeyWithName,
                                                                 serviceDict: emptyDict)
        let expected = """
        Missing dependency for String with name: name
        Container has a total of 0 dependencies.
        """
        XCTAssertEqual(expected, error.description)
    }

    func test_description_missingDependency_withServiceKeyName_similarDependencies() {
        let factory = FactoryDefinition(name: nil, factory: { _ in "" })
        let serviceDict: ServiceDictionary<DependencyDefinition> = ServiceDictionary<DependencyDefinition>()
        serviceDict[ServiceKey(String.self, name: "other_name")] = factory
        serviceDict[ServiceKey(String.self)] = factory
        let error = DependencyError.createMissingDependencyError(missingDependency: serviceKeyWithName,
                                                                 serviceDict: serviceDict)
        let expected = """
        Missing dependency for String with name: name
        Container has a total of 2 dependencies.
        Similar dependencies:
        - String with name: <no name>
        - String with name: other_name
        """
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
