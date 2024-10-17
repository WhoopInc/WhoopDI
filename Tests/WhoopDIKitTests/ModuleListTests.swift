import Testing
@testable import WhoopDIKit

class ModuleListTests {
    @Test
    func emptyModuleList() {
        #expect(EmptyModuleList().modules.isEmpty)
    }
}
