import MetalKit

///protocol for a struct to be automatically declared in Metal library source
///
///the Swift types allowed:
///SIMDN<type>,  2<N<4, type - any key from swiftTypesToMetalTypes dictionary
///For the scalar type use Float
///
///Unfortunately, there is no native way of differing between scalar Swift types,
///hence only one scalar type is allowed: Float
public protocol MetalStruct{
    init()
}
    ///returns string containing the C-struct declaration
func metalTypeDeclaration<T>(from swiftType: T, name: String?) -> MetalTypeDeclaration?{
    guard let type = swiftType as? MetalStruct.Type
    else{ return nil }
    let mirror = Mirror(reflecting: type.init())
    var metalName: String
    if let name = name{
        metalName = name
    }else{
        metalName = String(describing: mirror.subjectType)
    }
    var s = "struct " + metalName + "{\n"
    for child in mirror.children {
        if let label = child.label{
            let type = String(describing: child.value.self)
            guard let metalType = reflectedTypeToMetalType(type)
            else{
                print("invalid type: ", type)
                return nil
            }
            s += "   "
            s += metalType + " "
            s += String(describing: label) + ";\n"
        }
    }
    s += "};\n"
    return MetalTypeDeclaration(typeName: metalName, declaration: s)
}

struct MetalTypeDeclaration{
    let typeName: String
    let declaration: String
}

func reflectedTypeToMetalType(_ type: String)->String?{
    var metalType = ""
    
    if let simdRange = type.range(of: "SIMD"){
        let dimRange = type[simdRange.lowerBound...]
        guard let dim = dimRange.rangeOfCharacter(from: ["2", "3", "4"])
        else { return nil }
        let typeRange = type[dim.lowerBound...]
        
        var mType: String?
        for type in swiftTypesToMetalTypes{
            if let _ = typeRange.range(of: type.key){
                mType = type.value
            }
        }
        guard let mType = mType
        else{ return nil }
        metalType += mType
        metalType += type[dim]
    }else{
        //if SIMD not found assumng that type is float!!
        metalType += "float"
    }
        return metalType
}
