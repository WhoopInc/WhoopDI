import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

struct InjectableInitMacro: PeerMacro {
    static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard declaration.kind == .initializerDecl else {
            throw MacroExpansionErrorMessage("@InjectableInit can only be applied to an initializer")
        }

        return []
    }
}
