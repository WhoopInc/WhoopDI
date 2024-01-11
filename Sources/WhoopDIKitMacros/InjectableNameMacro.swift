import SwiftSyntax
import SwiftSyntaxMacros

/// This macro is just to have a marker, it does not actually do anything without the `@Injectable` macro
struct InjectableNameMacro: PeerMacro {
    static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        []
    }
}
