
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UniformsStructMacro: MemberMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
                throw UniformsStructError.onlyApplicableToStruct
        }
        let members = structDecl.memberBlock.members
        let variableDecl = members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        
        let propertiesInfo: [Property_string] = try variableDecl.map{
            let name = $0.bindings.first!.pattern
            let decl = $0.bindings.first?.initializer?.value.as(FunctionCallExprSyntax.self)
                
            guard let type = decl?.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName,
                  "\(type)" == "Uniform" else{
                throw UniformsStructError.shouldBeAllProperty
            }
            
            let arguments = decl!.arguments.as(LabeledExprListSyntax.self)!
            
            let initValue = arguments.first!.expression
                .as(FunctionCallExprSyntax.self)!
            
            let bindingT = initValue.calledExpression.as(DeclReferenceExprSyntax.self)!.baseName
            let range = arguments.dropFirst().first!.expression
                .as(SequenceExprSyntax.self)!
            
            var editable = "true"
            if let editableArg = arguments.dropFirst(2).first?.expression
                .as(BooleanLiteralExprSyntax.self){
                editable = "\(editableArg)"
            }
            
            return Property_string(name: "\(name)",
                                   bindingT: "\(bindingT)",
                                   range: "\(range)",
                                   initValue: "\(initValue)",
                                   editable: editable)
        }
        
        let initialCode =  "init(buffer: MTLBufferContainer<UInt8>, setOffset: (Int)->())"
        let initialCodeNode = SyntaxNodeString(stringLiteral: initialCode)
        
        let initializer = try InitializerDeclSyntax(initialCodeNode) {
            DeclSyntax("var offset = 0")
            for prop in propertiesInfo{
                ExprSyntax("""
                \(raw: prop.name)= Uniform(binding: Binding<\(raw: prop.bindingT)>(get: {
                                                    buffer.getUniformValue(offset: offset)
                                                }, set: { value in
                                                    buffer.setUniformValue(value, offset: offset)
                                                }),
                                     range: \(raw: prop.range),
                                     initValue: \(raw: prop.initValue),
                                     editable: \(raw: prop.editable),
                                     offset: offset)
                """)
                ExprSyntax("""
                offset += MemoryLayout.stride(ofValue: \(raw: prop.initValue))
                """)
            }
            ExprSyntax("setOffset(offset)")
        }
            
        return [DeclSyntax(initializer)]
    }
}

struct Property_string{

    let name: String
    let bindingT: String
    let range: String
    let initValue: String
    let editable: String
    
    //public var offset: Int = 0
}

enum UniformsStructError: CustomStringConvertible, Error {
    case onlyApplicableToStruct, shouldBeAllProperty
    
    var description: String {
        switch self {
        case .onlyApplicableToStruct: return "@UniformsStruct can only be applied to a structure"
        case .shouldBeAllProperty: return "The members of UniforStruct should all be initialized to an instance of Property type."
        }
    }
}
