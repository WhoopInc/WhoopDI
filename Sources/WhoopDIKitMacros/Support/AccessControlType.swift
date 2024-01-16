import SwiftSyntax

enum AccessControlType: String {
    case `public`
    case `private`
    case `internal`
    case `fileprivate`
}

extension DeclModifierListSyntax {
    var accessModifier: String? {
        return compactMap { modifier in
            AccessControlType(rawValue: modifier.name.text)?.rawValue
        }.first
    }
}
