import XCTest
@testable import WhoopDIKit

final class DefinitionDictionaryProviderTests: XCTestCase {
    func test_standard_provideDictionary() {
        assertDefinitionDictionaryMutated(provider: StandardDefinitionDictionaryProvider())
    }
    
    func test_threadSafe_provideDictionary() {
        assertDefinitionDictionaryMutated(provider: ThreadSafeDefinitionDictionaryProvider())
    }
    
    private func assertDefinitionDictionaryMutated(provider: DefinitionDictionaryProvider) {
        provider.provide { dict in
            dict[String.self] = FactoryDefinition(name: nil) { _ in "" }
            dict[Int.self] = FactoryDefinition(name: nil) { _ in 42 }
        }
        let keys = provider.provide { dict in dict.allKeys() }
        
        let expected: Set<AnyHashable> = [ServiceKey(String.self), ServiceKey(Int.self)]
        XCTAssertEqual(expected, keys)
    }
}
