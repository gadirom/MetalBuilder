// Save this as PropertyCollectorMacros.swift

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// Helper struct to store property information
struct PropertyInfo {
    let name: String
    let type: String
}

// Define error types
enum MacroError: Error, CustomStringConvertible {
    case notAClass
    case invalidParentClassName
    
    var description: String {
        switch self {
        case .notAClass:
            return "@AutoInherit can only be applied to class declarations"
        case .invalidParentClassName:
            return "Parent class name must be provided as a string literal"
        }
    }
}

// Macro to add members for property collection
public struct PropertyCollectorMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Make sure we're dealing with a class declaration
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw MacroError.notAClass
        }
        
        // Parse the parent class name from the attribute arguments
        guard let argument = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression,
              let stringLiteral = argument.as(StringLiteralExprSyntax.self),
              let _ = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text else {
            throw MacroError.invalidParentClassName
        }
        
        // Extract all properties from the class
        var properties: [PropertyInfo] = []
        for member in classDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Only process stored properties
                guard varDecl.bindingSpecifier.text == "var" || varDecl.bindingSpecifier.text == "let" else {
                    continue
                }
                
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                       let type = binding.typeAnnotation?.type {
                        properties.append(PropertyInfo(name: identifier, type: type.description))
                    }
                }
            }
        }
        
        // Generate the collectProperties() method using string literal syntax
        let collectPropertiesDecl = DeclSyntax("""
        override func collectProperties() {
            super.collectProperties()
            self._collectedProperties = [
                \(raw: properties.map { "self.\($0.name)" }.joined(separator: ",\n                "))
            ]
        }
        """)
        
        // Generate the modified initializer using string literal syntax
        let initDecl = DeclSyntax("""
        override init() {
            super.init()
            collectProperties()
        }
        """)
        
        return [collectPropertiesDecl, initDecl]
    }
}

// Define a peer macro to establish the inheritance
extension PropertyCollectorMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw MacroError.notAClass
        }
        
        // Parse the parent class name from the attribute arguments
        guard let argument = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression,
              let stringLiteral = argument.as(StringLiteralExprSyntax.self),
              let parentClassName = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text else {
            throw MacroError.invalidParentClassName
        }
        
        // Create an extension that adds the inheritance relationship using string literal
        let extensionDecl = DeclSyntax("""
        extension \(raw: classDecl.name.text): \(raw: parentClassName) {}
        """)
        
        return [extensionDecl]
    }
}
