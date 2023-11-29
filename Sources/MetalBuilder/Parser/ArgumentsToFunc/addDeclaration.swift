
import Foundation

func addArgumentsDeclaration(of arguments: [MetalFunctionArgument],
                             toHeaderOf function: MetalFunction,
                             in source: inout String) throws{
    let bracketId = try findFunction(function, in: source)
    
    let comma: String
    
    if source[source.index(bracketId.lowerBound, offsetBy: 1)] == function.closeBrace{
        comma = function.ending
    }else{
        comma = function.divisor
    }
    var string = ""
    for argument in arguments{
        if string != ""{
            string += function.divisor
        }
        string += try argument.string()
    }
    source.replaceSubrange(bracketId, with: function.openBrace.lowercased() + string + comma)
}
