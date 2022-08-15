
import MetalKit

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

    if let type = simdTypeToMetal(type){
        metalType = type
    }else{
        //if SIMD not found assumng that type is float!!
        metalType += "float"
    }
    return metalType
}

func metalType(for swiftType: String)->String?{

    if let metalType = simdTypeToMetal(swiftType){
        return metalType
    }
    //if SIMD not found trying to get non-vector type
    if let metalType = swiftTypesToMetalTypes[swiftType]{
        return metalType
    }
    return nil
}

func simdTypeToMetal(_ simdType: String)->String?{
    guard let simdRange = simdType.range(of: "SIMD")
    else{ return nil }
    let dimRange = simdType[simdRange.lowerBound...]
    guard let dim = dimRange.rangeOfCharacter(from: ["2", "3", "4"])
    else { return nil }
    let postSIMDRange = simdType[dim.lowerBound...]
    
    let rightBracket = postSIMDRange.rangeOfCharacter(from: [">"])!
    let leftTypeIndex = simdType.index(simdRange.upperBound, offsetBy: 2)
    let rightTypeIndex = simdType.index(rightBracket.lowerBound, offsetBy: -1)
    let type = String(simdType[leftTypeIndex...rightTypeIndex])
    
    let mType = swiftTypesToMetalTypes[type]
    
    guard let mType = mType
    else{ return nil }
    return mType+simdType[dim]
}

