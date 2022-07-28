
import Foundation

enum MetalFunction{
    case vertex(String), fragment(String), compute(String)
    var prefix: String{
        switch self{
        case .vertex(_): return "vertex"
        case .fragment(_): return "fragment"
        case .compute(_): return "kernel"
        }
    }
    var name: String{
        switch self{
        case .vertex(let name): return name
        case .fragment(let name): return name
        case .compute(let name): return name
        }
    }
}
