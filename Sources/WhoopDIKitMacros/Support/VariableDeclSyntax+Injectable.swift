import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

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

    var typeName: TypeSyntax? {
        guard let annotationType = self.bindings.first?.typeAnnotation?.type.trimmed else { return nil }
        if (annotationType.is(FunctionTypeSyntax.self)) {
            return "@escaping \(annotationType)"
        } else {
            return annotationType
        }
    }

    var isInstanceAssignableVariable: Bool {
        return !isStaticOrLazy && !isLetWithValue && isStoredProperty
    }
}
