import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// Compiler plugin
@main
struct AutoInheritPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FieldMacro.self,
        EditableMacro.self
        //AutoInheritMacro.self,
        //PropertyCollectorMacro.self
    ]
}
