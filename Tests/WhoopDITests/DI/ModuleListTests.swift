import XCTest
@testable import WhoopDI

class ModuleListTests: XCTestCase {
    func test_emptyModuleList() {
        XCTAssertTrue(EmptyModuleList().modules.isEmpty)
    }
}
