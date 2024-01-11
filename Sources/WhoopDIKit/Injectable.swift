import Foundation

public protocol Injectable {
    static func inject() throws -> Self
}
