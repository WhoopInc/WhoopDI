import XCTest
@testable import WhoopDIKit

class ModuleListTests: XCTestCase {
    func test_emptyModuleList() {
        XCTAssertTrue(EmptyModuleList().modules.isEmpty)
    }
}
