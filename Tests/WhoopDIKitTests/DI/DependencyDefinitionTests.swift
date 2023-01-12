import XCTest
@testable import WhoopDIKit

class DependencyDefinitionTests: XCTestCase {
    func test_factory_get_noParams() {
        let definition = FactoryDefinition(name: nil) { _ in "value" }
        XCTAssertEqual("value", try definition.get(params: nil) as! String)
    }
    
    func test_factory_get_throwsOnNil() {
        let expectedError = DependencyError.nilDependency(ServiceKey(Optional<String>.self))
        let definition = FactoryDefinition(name: nil) { _ in nil as String? }
        
        XCTAssertThrowsError(try definition.get(params: nil)) { error in
            XCTAssertEqual(expectedError, error as! DependencyError)
        }
    }
    
    func test_factory_get_withParams() {
        let definition = FactoryDefinition(name: nil) { params in "value with \(params as! String)" }
        XCTAssertEqual("value with a param", try definition.get(params: "a param") as! String)
    }
    
    func test_factory_serviceKey_noName() {
        let definition = FactoryDefinition(name: nil) { _ in "value" }
        XCTAssertEqual(ServiceKey(String.self, name: nil), definition.serviceKey)
    }
    
    func test_factory_serviceKey_withName() {
        let definition = FactoryDefinition(name: "name") { _ in "value" }
        XCTAssertEqual(ServiceKey(String.self, name: "name"), definition.serviceKey)
    }
    
    func test_singleton_get_createdExactlyOnce() {
        var callCount = 0
        let definition = SingletonDefinition(name: nil) { _ -> Int in
            callCount += 1
            return callCount
        }
        
        XCTAssertEqual(1, try definition.get(params: nil) as! Int)
        XCTAssertEqual(1, try definition.get(params: nil) as! Int)
    }
    
    func test_singleton_get_recoversFromThrow() {
        let expectedError = DependencyError.missingDependecy(ServiceKey(String.self))
        var callCount = 0
        let definition = SingletonDefinition(name: nil) { _ -> Int in
            callCount += 1
            if callCount == 1 {
                throw expectedError
            }
            return callCount
        }
        
        XCTAssertThrowsError(try definition.get(params: nil)) { error in
            XCTAssertEqual(expectedError, error as! DependencyError)
        }
        
        XCTAssertEqual(2, try definition.get(params: nil) as! Int)
        XCTAssertEqual(2, try definition.get(params: nil) as! Int)
    }
    
    func test_singleton_get_throwsOnNil() {
        let expectedError = DependencyError.nilDependency(ServiceKey(Optional<String>.self))
        let definition = SingletonDefinition(name: nil) { _ in nil as String? }
        
        XCTAssertThrowsError(try definition.get(params: nil)) { error in
            XCTAssertEqual(expectedError, error as! DependencyError)
        }
    }
    
    func test_singleton_get_withParams() {
        let definition = SingletonDefinition(name: nil) { params in "value with \(params as! String)" }
        XCTAssertEqual("value with a param", try definition.get(params: "a param") as! String)
    }
    
    func test_singleton_serviceKey_noName() {
        let definition = SingletonDefinition(name: nil) { _ in "value" }
        XCTAssertEqual(ServiceKey(String.self, name: nil), definition.serviceKey)
    }
    
    func test_singleton_serviceKey_withName() {
        let definition = SingletonDefinition(name: "name") { _ in "value" }
        XCTAssertEqual(ServiceKey(String.self, name: "name"), definition.serviceKey)
    }
}
