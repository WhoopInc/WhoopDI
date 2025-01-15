import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

struct VariableDeclaration {
    let name: String
    let type: TypeSyntax
    let defaultExpression: ExprSyntax?
    let injectedName: ExprSyntax?
}

extension DeclGroupSyntax {
    var allMemberVariables: [VariableDeclaration] {
        let allMembers = self.memberBlock.members
        // Go through all members and return valid variable declarations when needed
        return allMembers.compactMap { (memberBlock) -> VariableDeclaration? in
            // Only do this for stored properties that are not `let` with a value (since those are constant)
            guard let declSyntax = memberBlock.decl.as(VariableDeclSyntax.self),
                  let propertyName = declSyntax.variableName,
                  let typeName = declSyntax.typeName
            else { return nil }
            guard declSyntax.isInstanceAssignableVariable else { return nil }

            // If the code has `InjectableName` on it, get the name to use
            let injectedName = injectableName(variableSyntax: declSyntax)

            /// Use the equality expression in the initializer as the default value (since that is how the memberwise init works)
            /// Example:
            ///  var myValue: Int = 100
            ///  Becomes
            ///  init(..., myValue: Int = 100)
            let equalityExpression = declSyntax.bindings.first?.initializer?.value
            return VariableDeclaration(name: propertyName,
                                       type: typeName,
                                       defaultExpression: equalityExpression,
                                       injectedName: injectedName)
        }
    }

    var allInjectableInits: [InitializerDeclSyntax] {
        self.memberBlock.members.compactMap { member in
            if let initSyntax = member.decl.as(InitializerDeclSyntax.self),
               initSyntax.attributes.contains(where: { element in
                   switch element {
                   case .attribute(let syntax):
                       return syntax.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "InjectableInit"
                   default:
                       return false
                   }
               }) {
                return initSyntax
            } else {
                return nil
            }
        }
    }

    private func injectableName(variableSyntax: VariableDeclSyntax) -> ExprSyntax? {
        variableSyntax.attributes.compactMap { attribute -> ExprSyntax? in
            switch attribute {
            case .attribute(let syntax):
                // Check for `InjectableName` and then get the name from it
                guard let name = syntax.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
                        name == "InjectableName" else { return nil }
                return syntax.arguments?.injectableNameExpression
            default: return nil
            }
        }.first
    }
}
