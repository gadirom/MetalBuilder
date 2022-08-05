
struct FunctionAndArguments{
    let function: MetalFunction
    var arguments: [MetalFunctionArgument]
}

public struct SwiftTypeToMetal {
    let swiftType: Any.Type
    let metalType: String?
}

func parse(library: inout String,
           funcArguments: [FunctionAndArguments]) throws{
    
    var funcArguments = funcArguments
    var metalTypeNames: [String] = []

    for funcAndArgID in funcArguments.indices{
        for argID in funcArguments[funcAndArgID].arguments.indices{
            let arg = funcArguments[funcAndArgID]
                .arguments[argID]
            if case let .buffer(buf) = arg{
                let type = buf.swiftTypeToMetal
                let metalDeclaration = metalTypeDeclaration(from: type.swiftType,
                                                            name: type.metalType)
                if let metalDeclaration = metalDeclaration{
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
            }
        }
    }
    for funcAndArg in funcArguments {
        try addDeclaration(of: funcAndArg.arguments,
                           toHeaderOf: funcAndArg.function, in: &library)
    }
    print(library)
}
