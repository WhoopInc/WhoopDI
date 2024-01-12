import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

private struct VariableDeclaration {
    let name: String
    let type: IdentifierTypeSyntax
    let defaultExpression: ExprSyntax?
    let injectedName: String?
}

struct InjectableMacro: ExtensionMacro, MemberMacro {
    /// Adds the `inject` and `init` function that we use for the `Injectable` protocol
    static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        // We only want to work for classes, structs, and actors
        guard [SwiftSyntax.SyntaxKind.classDecl, .structDecl, .actorDecl].contains(declaration.kind) else {
            throw MacroExpansionErrorMessage("@Injectable needs to be declared on a concrete type, not a protocol")
        }

        let allMembers = declaration.memberBlock.members
        // Go through all members and return valid variable declarations when needed
        let allVariables = allMembers.compactMap { (memberBlock) -> VariableDeclaration? in
            // Only do this for stored properties that are not `let` with a value (since those are constant)
            guard let declSyntax = memberBlock.decl.as(VariableDeclSyntax.self),
                  declSyntax.isStoredProperty,
                  !declSyntax.isLetWithValue,
                  !declSyntax.isStaticOrLazy,
                  let propertyName = declSyntax.variableName,
                  let typeName = declSyntax.typeName
            else { return nil }

            // If the code has `InjectableName` on it, get the name to use
            let injectedName = declSyntax.attributes.compactMap { (attribute) -> String? in
                switch attribute {
                case .attribute(let syntax):
                    // Check for `InjectableName` and then get the name from it
                    guard let name = syntax.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
                            name == "InjectableName" else { return nil }
                    return syntax.arguments?.labeledContent
                default: return nil
                }
            }.first

            // Use the equality expression in the initializer so that people do not need to put a real value
            let equalityExpression = declSyntax.bindings.first?.initializer?.value
            return VariableDeclaration(name: propertyName, type: typeName, defaultExpression: equalityExpression, injectedName: injectedName)
        }

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
            """
            
            \(raw: accessLevel) static func inject() -> Self {
                Self.init(\(raw: injectingVariables))
            }
            """,
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


enum AccessorType: String {
    case `public`
    case `private`
    case `internal`
    case `fileprivate`
}

extension DeclModifierListSyntax {
    var accessModifier: String? {
        return compactMap { modifier in
            AccessorType(rawValue: modifier.name.text)?.rawValue
        }.first
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

extension VariableDeclSyntax {
    /// Determine whether this variable has the syntax of a stored property.
    ///
    /// This syntactic check cannot account for semantic adjustments due to,
    /// e.g., accessor macros or property wrappers.
    /// taken from https://github.com/apple/swift-syntax/blob/main/Examples/Sources/MacroExamples/Implementation/MemberAttribute/WrapStoredPropertiesMacro.swift
    var isStoredProperty: Bool {
        if bindings.count != 1 {
            return false
        }

        let binding = bindings.first!
        switch binding.accessorBlock?.accessors {
        case .none:
            return true

        case .accessors(let accessors):
            for accessor in accessors {
                switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.willSet), .keyword(.didSet):
                    // Observers can occur on a stored property.
                    break

                default:
                    // Other accessors make it a computed property.
                    return false
                }
            }

            return true

        case .getter:
            return false
        }
    }

    // Check if the token is a let and if there is a value in the initializer
    var isLetWithValue: Bool {
        self.bindingSpecifier.tokenKind == .keyword(.let) && bindings.first?.initializer != nil
    }

    // Check if the modifiers have lazy or static, in which case we wouldn't add it to the init
    var isStaticOrLazy: Bool {
        self.modifiers.contains { syntax in
            syntax.name.tokenKind == .keyword(.static) || syntax.name.tokenKind == .keyword(.lazy)
        }
    }

    var variableName: String? {
        self.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }

    var typeName: IdentifierTypeSyntax? {
        self.bindings.first?.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.trimmed
    }
}
