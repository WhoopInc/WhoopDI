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

        let allInjectableInits = declaration.allInjectableInits

        if allInjectableInits.isEmpty {
            return try createInitializerAndInject(declaration: declaration)
        } else if allInjectableInits.count > 1 {
            throw MacroExpansionErrorMessage("Only one initializer with the `@InjectableInit` macro is allowed")
        } else {
            let initValue = allInjectableInits[0]
            return try createInject(from: initValue, declaration: declaration)
        }
    }

    private static func createInject(from initValue: InitializerDeclSyntax, declaration: some DeclGroupSyntax) throws -> [DeclSyntax] {
        let allArgs = initValue.signature.parameterClause.parameters.map { parameter in
            "\(parameter.firstName.text == "_" ? "" : "\(parameter.firstName.text): ")container.inject()"
        }.joined(separator: ", ")

        let accessLevel = self.accessLevel(declaration: declaration) ?? "internal"

        return [
            """
            \(raw: accessLevel) static func inject(container: Container) -> Self {
                Self.init(\(raw: allArgs))
            }
            """
        ]
    }

    private static func createInitializerAndInject(declaration: some DeclGroupSyntax) throws -> [DeclSyntax] {
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
            "\(variable.name): container.inject(\(variable.injectedName.map { "\($0)" } ?? "nil"))"
        }.joined(separator: ", ")

        let accessLevel = self.accessLevel(declaration: declaration) ?? "internal"

        return [
            /// Adds the static inject function, such as:
            /// public static func inject() -> Self {
            ///     Self.init(myValue: WhoopDI.inject(nil))
            /// }
            """
            
            \(raw: accessLevel) static func inject(container: Container) -> Self {
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
    /// The expression associated with the name argument. `@InjectableName(name: <this>)`
    var injectableNameExpression: ExprSyntax? {
        switch self {
        case let .argumentList(strList):
            strList.filter { expr in expr.label?.text == "name" }.first?.expression
        default:
            nil
        }
    }
}
