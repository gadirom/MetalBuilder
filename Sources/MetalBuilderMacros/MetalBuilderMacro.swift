import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct MetalBuilderMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        UniformsStructMacro.self,
    ]
}
