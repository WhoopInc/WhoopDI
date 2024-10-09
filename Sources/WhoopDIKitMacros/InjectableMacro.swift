import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

struct InjectableMacro: ExtensionMacro, MemberMacro {
    /// Adds the `inject` and `init` function that we use for the `Injectable` protocol
    static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        // We only want to work for classes, structs, and actors
        guard [SwiftSyntax.SyntaxKind.classDecl, .structDecl, .actorDecl].contains(declaration.kind) else {
            throw MacroExpansionErrorMessage("@Injectable needs to be declared on a concrete type, not a protocol")
        }

        let allVariables = declaration.allMemberVariables

        // Create the initializer args in the form `name: type = default`
        let initializerArgs: String = allVariables.map { variable in
            "\(variable.name): \(variable.type)\(variable.defaultExpression.map { " = \($0)" } ?? "")"
        }.joined(separator: ", ")

        // Creates the intitializer body
        let initializerStoring: String = allVariables.map { variable in
            "self.\(variable.name) = \(variable.name)"
        }.joined(separator: "\n")

        // Creates the whoopdi calls in the `inject` func
        let injectingVariables: String = allVariables.map { variable in
            "\(variable.name): WhoopDI.inject(\(variable.injectedName.map { "\"\($0)\"" } ?? "nil"))"
        }.joined(separator: ", ")

        let accessLevel = self.accessLevel(declaration: declaration) ?? "internal"

        return [
            /// Adds the static inject function, such as:
            /// public static func inject() -> Self {
            ///     Self.init(myValue: WhoopDI.inject(nil))
            /// }
            """
            
            \(raw: accessLevel) static func inject() -> Self {
                Self.init(\(raw: injectingVariables))
            }
            """,
            /// Adds the memberwise init, such as:
            /// public init(myValue: String) {
            ///   self.myValue = myValue
            /// }
            """
            \(raw: accessLevel) init(\(raw: initializerArgs)) {
                \(raw: initializerStoring)
            }
            """
        ]
    }

    static func expansion(of node: SwiftSyntax.AttributeSyntax,
                          attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                          providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                          conformingTo protocols: [SwiftSyntax.TypeSyntax],
                          in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard [SwiftSyntax.SyntaxKind.classDecl, .structDecl, .actorDecl].contains(declaration.kind) else {
            throw MacroExpansionErrorMessage("@Injectable needs to be declared on a concrete type, not a protocol")
        }
        // Creates the extension to be Injectable (needs to be separate from member macro because member macros can't add protocols)
        guard let identified = declaration.asProtocol(NamedDeclSyntax.self) else { return [] }
        let name = identified.name
        let extensionSyntax: ExtensionDeclSyntax = try ExtensionDeclSyntax("extension \(name): Injectable { }")

        return [
            extensionSyntax
        ]
    }

    // Gets the access level fo the top level type
    private static func accessLevel(declaration: some DeclGroupSyntax) -> String? {
        switch declaration {
        case let decl as StructDeclSyntax:
            return decl.modifiers.accessModifier
        case let decl as ClassDeclSyntax:
            return decl.modifiers.accessModifier
        case let decl as ActorDeclSyntax:
            return decl.modifiers.accessModifier
        default:
            fatalError()
        }
    }
}

extension AttributeSyntax.Arguments {
    // Get the first string literal in the argument list to the macro
    var labeledContent: String? {
        switch self {
        case let .argumentList(strList):
            strList.compactMap { str in
                str.expression.as(StringLiteralExprSyntax.self)?.segments.compactMap { (segment) -> String? in
                    return switch segment {
                    case .stringSegment(let segment): segment.content.text
                    default: nil
                    }
                }.joined()
            }.first
        default:
            nil
        }
    }
}
