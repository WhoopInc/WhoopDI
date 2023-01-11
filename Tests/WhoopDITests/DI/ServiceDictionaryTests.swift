import XCTest
@testable import WhoopDI

final class ServiceDictionaryTests: XCTestCase {
    func test_subscript_typeKey() {
        let dict = ServiceDictionary<String>()
        dict[String.self] = "string"
        dict[Int.self] = "int"

        XCTAssertEqual("string", dict[String.self])
        XCTAssertEqual("int", dict[Int.self])
        XCTAssertNil(dict[Bool.self])
    }

    func test_subscript_serviceKey() {
        let dict = ServiceDictionary<String>()
        let serviceKey1 = ServiceKey(String.self, name: "name1")
        let serviceKey2 = ServiceKey(String.self, name: "name2")
        let serviceKey3 = ServiceKey(String.self, name: "name3")
        dict[serviceKey1] = "value1"
        dict[serviceKey2] = "value2"

        XCTAssertEqual("value1", dict[serviceKey1])
        XCTAssertEqual("value2", dict[serviceKey2])
        XCTAssertNil(dict[serviceKey3])
    }
    
    func test_add() {
        let dictA = ServiceDictionary<String>()
        dictA[String.self] = "string"
        dictA[Int.self] = "int"
        dictA[Bool.self] = "bool"
        
        let dictB = ServiceDictionary<String>()
        dictB[String.self] = "string2"
        dictB[Int.self] = "int2"
        
        let dictC: ServiceDictionary<String> = dictA + dictB
        
        XCTAssertEqual("string2", dictC[String.self])
        XCTAssertEqual("int2", dictC[Int.self])
        XCTAssertEqual("bool", dictC[Bool.self])
    }
}
