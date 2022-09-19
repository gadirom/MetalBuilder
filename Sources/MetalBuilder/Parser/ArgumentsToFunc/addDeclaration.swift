
import Foundation

func addDeclaration(of arguments: [MetalFunctionArgument],
                    toHeaderOf function: MetalFunction,
                    in source: inout String) throws{
    for argument in arguments{
        try addDeclaration(of: argument, toHeaderOf: function, in: &source)
    }
}

func addDeclaration(of argument: MetalFunctionArgument,
                    toHeaderOf function: MetalFunction,
                    in source: inout String) throws{
    let bracketId = try findFunction(function, in: source)
    
    let comma: String
    
    if source[source.index(bracketId.lowerBound, offsetBy: 1)]==")"{
        comma = ""
    }else{
        comma = ", "
    }
    let string = try argument.string()
    source.replaceSubrange(bracketId, with: "(" + string + comma)
}
