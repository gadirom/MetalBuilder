import SwiftSyntax
import SwiftSyntaxMacros

public enum CustomError: Error {
    case message(String)
}

// MARK: - Field Macro

public struct FieldMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let arguments = node.arguments?.as(TupleExprElementListSyntax.self),
              let firstArg = arguments.first?.expression,
              let secondArg = arguments.last?.expression,
              let stringLiteral = secondArg.as(StringLiteralExprSyntax.self),
              let value = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text
                //              let varDecl = declaration.as(VariableDeclSyntax.self),
                //              let binding = varDecl.bindings.first,
                //              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                //let memberAccessExpr = argument.as(MemberAccessExprSyntax.self)//,
              //let baseExpr = memberAccessExpr.base?.description,
//              let memberName = memberAccessExpr.name.text
              //baseExpr == "FieldStyle"
                   // Combined they form your type reference
        else {
            throw CustomError.message("@Field requires a FieldStyle and String(title) argument on a variable.")
        }
        return [""]//let _\(raw: identifier) = \"\(raw: value)\""]
    }
}

// MARK: - DictionarySubscript Macro

public struct EditableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw CustomError.message("This macro can only be applied to a struct.")
        }
        
        var fields: [(name: String,
                      value: String,
                      type: String,
                      simd: Bool,
                      count: String,
                      getter: (String)->String,
                      setter: String,
                      integer: Bool)] = []
        
        for member in structDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Check each binding (there could be multiple in a single var declaration)
                for binding in varDecl.bindings {
                    // Examine the pattern to get the variable name
                    if let patternIdentifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        let variableName = patternIdentifier.identifier.text
                        
                        // Look for the Peer attribute in the variable's attributes
                        for attribute in varDecl.attributes {
                            if let attrSyntax = attribute.as(AttributeSyntax.self),
                               let attributeName = attrSyntax.attributeName.as(IdentifierTypeSyntax.self),
                               attributeName.name.text == "Field" {
                                
                                // Check if it has arguments
                                if let arguments = attrSyntax.arguments?.as(TupleExprElementListSyntax.self),
                                   let typeAnnotation = binding.typeAnnotation
                                {
                                    var type = typeAnnotation.type.description.trimmingCharacters(in: .whitespaces)
                                    
                                    let integer =
                                    !((type.range(of: "float", options: .caseInsensitive) != nil)
                                    || type.contains("half"))
                                    
                                    var simd = false
                                    var count = "1"
                                    //if simd: simd_float3 -> simd_float1
                                    if type.contains("simd_") && !type.hasSuffix("1"){
                                        //type = type.replacingOccurrences(of: "simd_", with: "")
                                        count = String(type.last!)//.hexDigitValue!
                                        
                                        type = type.trimmingCharacters(in: .decimalDigits)
                                        type = type+"1"
                                        simd = true
                                    }
                                    
                                    var getter: (String)->(String) = {"Double(\($0))"}
                                    var setter = "\(type)(newValue)"
                                    
                                    if type.range(of: "bool", options: .caseInsensitive) != nil{
                                        getter = {"Double(\($0) ? 1 : 0)"}
                                        setter = "\(type)(Float(newValue)==1)"
                                    }
                                        
                                    fields.append((name: variableName,
                                                   value: arguments.description,
                                                   type: type,
                                                   simd: simd,
                                                   count: count,
                                                   getter: getter,
                                                   setter: setter,
                                                   integer: integer))
                                    
                                } else {
                                    // Handle Peer attribute without arguments
//                                        context.diagnose(Diagnostic(
//                                            node: attribute,
//                                            message: "Found Peer attribute without arguments"
//                                        ))
                                }
                            }
                        }
                    }
                }
            }
        }
        
        let dictEntries = fields.map {
            "\"\($0.name)\": (\($0.value), \($0.count), \($0.integer))"
        }.joined(separator: ", ")
        let dictProperty: DeclSyntax = if dictEntries.isEmpty{
        ""
        }else{
        """
        public var dict: OrderedDictionary<String, (FieldStyle, String, Int, Bool)>{
            [\(raw: dictEntries)]
        }
        """}
        
        let subscriptCasesGet = fields.map {
            "case \"\($0.name)\": \($0.getter("\($0.name)\($0.simd ? "[index]" : "")"))"
        }.joined(separator: "\n")
        
        let subscriptCasesSet = fields.map {
        """
        case \"\($0.name)\": self.\($0.name)\($0.simd ? "[index]" : "") = \($0.setter)
        """
        }.joined(separator: "\n")
        
        
        let subscriptDecl: DeclSyntax = """
        public subscript(key: String, index: Int) -> any BinaryFloatingPoint {
            get {
                switch key {
                \(raw: subscriptCasesGet)
                default: fatalError("Invalid key: \\(key)")
                }
            }
            set {
                switch key {
                \(raw: subscriptCasesSet)
                default: fatalError("Invalid key: \\(key)")
                }
            }
        }
        """
        
        return [dictProperty, subscriptDecl]
    }
}

//simdType = Type
//
//let singleValue: any BinaryFloatingPoint = newValue as! (any BinaryFloatingPoint)
//
//if simdType != nil{
//    self.name[index] = Float16(singleValue)
//}else{
//    self.name = Float16(singleValue)
//}
