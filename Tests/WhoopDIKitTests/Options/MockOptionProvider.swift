import Foundation
@testable import WhoopDIKit

struct MockOptionProvider: WhoopDIOptionProvider {
    private let options: [WhoopDIOption: Bool]
    
    init(options: [WhoopDIOption : Bool] = [:]) {
        self.options = options
    }
    
    func isOptionEnabled(_ option: WhoopDIOption) -> Bool {
        options[option] ?? false
    }
}
