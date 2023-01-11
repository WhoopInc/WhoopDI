import XCTest
@testable import WhoopDI

final class ServiceKeyTests: XCTestCase {
    func test_hash_nilName() {
        let key = ServiceKey(String.self)
        let expected = ObjectIdentifier(String.self).hashValue
        XCTAssertEqual(expected, key.hashValue)
    }
    
    func test_hash_nonNilName() {
        let key = ServiceKey(String.self, name: "name")
        
        var hasher = Hasher()
        hasher.combine(ObjectIdentifier(String.self))
        "name".hash(into: &hasher)
        XCTAssertEqual(hasher.finalize(), key.hashValue)
    }

    func test_equality_equalTypesAndNames() {
        let key1 = ServiceKey(String.self, name: "name")
        let key2 = ServiceKey(String.self, name: "name")
        
        XCTAssertEqual(key1, key2)
    }
    
    func test_equality_equalTypesAndNilNames() {
        let key1 = ServiceKey(String.self)
        let key2 = ServiceKey(String.self)
        
        XCTAssertEqual(key1, key2)
    }
    
    func test_equality_unequalNames() {
        let key1 = ServiceKey(String.self, name: "name1")
        let key2 = ServiceKey(String.self, name: "name2")
        
        XCTAssertNotEqual(key1, key2)
    }
    
    func test_equality_unequalTypes() {
        let key1 = ServiceKey(String.self, name: "name")
        let key2 = ServiceKey(Int.self, name: "name")
        
        XCTAssertNotEqual(key1, key2)
    }
    
    func test_equality_unequalTypesAndNames() {
        let key1 = ServiceKey(String.self, name: "name1")
        let key2 = ServiceKey(Int.self, name: "name2")
        
        XCTAssertNotEqual(key1, key2)
    }
    
    func test_equality_unequalTypesAndNilNames() {
        let key1 = ServiceKey(String.self)
        let key2 = ServiceKey(Int.self)
        
        XCTAssertNotEqual(key1, key2)
    }
}
