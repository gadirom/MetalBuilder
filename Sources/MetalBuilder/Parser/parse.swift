
struct FunctionAndArguments{
    let function: MetalFunction
    var arguments: [MetalFunctionArgument]
}
extension FunctionAndArguments: Equatable{
    static func == (lhs: FunctionAndArguments, rhs: FunctionAndArguments) -> Bool {
        lhs.function == rhs.function
    }
}

public struct SwiftTypeToMetal{
    let swiftType: Any.Type
    let metalType: String?
}

func parse(library: inout String,
           funcArguments: [FunctionAndArguments]) throws{
    
    var funcArguments = funcArguments.noDublicates()
    var metalTypeNames: [String] = []
    var structDeclarations: String = ""
    var referenceStructsDecls: String = ""

    for funcAndArgID in funcArguments.indices{
        for argID in funcArguments[funcAndArgID].arguments.indices{
            let arg = funcArguments[funcAndArgID].arguments[argID]
            switch arg{
            case .buffer(let buf):
                if let metalDeclaration = buf.metalDeclaration{
                    if !metalTypeNames.contains(metalDeclaration.typeName) {
                        metalTypeNames.append(metalDeclaration.typeName)
                        structDeclarations += metalDeclaration.declaration
                    }
                    
                    if buf.passAs.isStructReference{
                        //add struct decl
                        let structName = buf.passAs.structName
                        if !metalTypeNames.contains(structName) {
                            metalTypeNames.append(structName)
                            referenceStructsDecls += buf.passAs
                                .referenceStructDecl(type: metalDeclaration.typeName,
                                                     count: buf.count)
                        }
                        
                        //change argument to struct
                        var bufArg = buf
                        bufArg.type = structName
                        let argNew: MetalFunctionArgument =
                            .buffer(bufArg)
                        funcArguments[funcAndArgID]
                           .arguments[argID] = argNew
                    }else{
                        
                        if buf.type == nil{// add type name to function declaration if there was no type set in the component
                            var bufArg = buf
                            bufArg.type = metalDeclaration.typeName
                            let argNew: MetalFunctionArgument =
                                .buffer(bufArg)
                            funcArguments[funcAndArgID]
                                .arguments[argID] = argNew
                        }
                    }
                }
            case .bytes(let bytes):
                
                if let metalDeclaration = bytes.metalDeclaration{
                    if !metalTypeNames.contains(metalDeclaration.typeName) {
                        metalTypeNames.append(metalDeclaration.typeName)
                        structDeclarations += metalDeclaration.declaration
                    }
                    
                    if bytes.type == nil{// add type name to function declaration if there was no type set in the component
                        var bytesArg = bytes
                        bytesArg.type = metalDeclaration.typeName
                        let argNew: MetalFunctionArgument =
                            .bytes(bytesArg)
                        funcArguments[funcAndArgID]
                           .arguments[argID] = argNew
                    }
                }else{
                    if bytes.type == nil{// if no type provided trying to assess an ordinary type (float, int, ect.)
                        let swiftType = bytes.swiftType
                        
                        guard let metalType = metalType(for: swiftType) else {
                            throw MetalBuilderParserError
                                .wrongType("Bytes `" +
                                           bytes.name +
                                           "` for function `" +
                                           funcArguments[funcAndArgID].function.name +
                                           "` " +
                                           "are wrong type: "+String(describing: swiftType))
                        }
                        var bytesArg = bytes
                        bytesArg.type = metalType
                        let argNew: MetalFunctionArgument =
                            .bytes(bytesArg)
                        funcArguments[funcAndArgID]
                           .arguments[argID] = argNew
                    }
                }
            default: break
            }
       
        }
    }
    library = structDeclarations + referenceStructsDecls + library
    for funcAndArg in funcArguments {
        try addArgumentsDeclaration(of: funcAndArg.arguments,
                           toHeaderOf: funcAndArg.function, in: &library)
    }
    print(library)
}

extension Array where Element: Equatable{
    func noDublicates()->[Element]{
        var out: [Element] = []
        for f in self{
            if !out.contains(where: { $0 == f }){
                out.append(f)
            }
        }
        return out
    }
    mutating func appendUnique(_ element: Element){
        if !self.contains(where: { $0 == element}){
            self.append(element)
        }
    }
}

extension Array where Element == BufferProtocol{
    func noDublicates()->[Element]{
        var out: [Element] = []
        for f in self{
            if !out.contains(where: { $0 === f }){
                out.append(f)
            }
        }
        return out
    }
}
