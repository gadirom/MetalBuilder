
import Foundation

enum MetalFunction: Equatable{
    case vertex(String), fragment(String), compute(String), argBuffer(String)
    var prefix: String{
        switch self{
        case .vertex(_): return "vertex"
        case .fragment(_): return "fragment"
        case .compute(_): return "kernel"
        case .argBuffer(_): return "struct"
        }
    }
    var name: String{
        switch self{
        case .vertex(let name): return name
        case .fragment(let name): return name
        case .compute(let name): return name
        case .argBuffer(let argBufTypeName): return argBufTypeName
        }
    }
    var openBrace: Character{
        if case .argBuffer(_) = self{
           return "{"
        }else{
            return "("
        }
    }
    var closeBrace: Character{
        if case .argBuffer(_) = self{
           return "}"
        }else{
            return ")"
        }
    }
    var divisor: String{
        if case .argBuffer(_) = self{
           return ";\n"
        }else{
            return ", "
        }
    }
    var ending: String{
        if case .argBuffer(_) = self{
           return ";\n"
        }else{
            return ""
        }
    }
}
