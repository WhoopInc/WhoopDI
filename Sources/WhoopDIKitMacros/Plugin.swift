import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct WhoopDIKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectableMacro.self, 
        InjectableNameMacro.self,
        InjectableInitMacro.self
    ]
}
