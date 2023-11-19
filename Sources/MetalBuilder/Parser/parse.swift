
struct FunctionAndArguments{
    let function: MetalFunction
    var arguments: [MetalFunctionArgument]
}

public struct SwiftTypeToMetal{
    let swiftType: Any.Type
    let metalType: String?
}

enum MetalBuilderParserError: Error{
    case syntaxError(String), wrongType(String)
}

func parse(library: inout String,
           funcArguments: [FunctionAndArguments]) throws{
    
    var funcArguments = funcArguments
    deleteDublicateFuncs(&funcArguments)
    var metalTypeNames: [String] = []

    for funcAndArgID in funcArguments.indices{
        for argID in funcArguments[funcAndArgID].arguments.indices{
            let arg = funcArguments[funcAndArgID].arguments[argID]
            switch arg{
            case .buffer(let buf):
                let type = buf.swiftTypeToMetal
                if let metalDeclaration = metalTypeDeclaration(from: type.swiftType,
                                                               name: type.metalType){
                    if !metalTypeNames.contains(metalDeclaration.typeName) {
                        metalTypeNames.append(metalDeclaration.typeName)
                        library = metalDeclaration.declaration + library
                    }
                    
                    if buf.type == nil{// add type name to function declaration if there was no type set in the component
                        var bufArg = buf
                        bufArg.type = metalDeclaration.typeName
                        let argNew: MetalFunctionArgument =
                            .buffer(bufArg)
                        funcArguments[funcAndArgID]
                           .arguments[argID] = argNew
                    }
                }
            case .bytes(let bytes):
                let metalDeclaration: MetalTypeDeclaration?
                let type = bytes.swiftTypeToMetal
                if let decl = bytes.metalDeclaration{
                    metalDeclaration = decl
                }else{
                    metalDeclaration = metalTypeDeclaration(from: type.swiftType,
                                                            name: type.metalType)
                }
                if let metalDeclaration = metalDeclaration{
                    if !metalTypeNames.contains(metalDeclaration.typeName) {
                        metalTypeNames.append(metalDeclaration.typeName)
                        library = metalDeclaration.declaration + library
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
                        let swiftType = type.swiftType
                        
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
    for funcAndArg in funcArguments {
        try addDeclaration(of: funcAndArg.arguments,
                           toHeaderOf: funcAndArg.function, in: &library)
    }
    print(library)
}

func deleteDublicateFuncs(_ fa: inout [FunctionAndArguments]){
    var faOut: [FunctionAndArguments] = []
    for f in fa{
        if !faOut.contains(where: { $0.function == f.function }){
            faOut.append(f)
        }
    }
    fa = faOut
}
