import Foundation
import Testing
@testable import WhoopDIKit

struct DefaultOptionProviderTests {
    @Test func defaults() async throws {
        let options = DefaultOptionProvider()
        #expect(options.isOptionEnabled(.threadSafeLocalInject) == false)
    }
}

