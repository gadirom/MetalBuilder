
import Foundation

enum MetalBuilderFunctionArgumentsError: Error {
case bufferArgumentError(String), textureArgumentError(String)
}

public enum MetalFunctionArgument{
    case texture(MetalTextureArgument),
         buffer(MetalBufferArgument),
         bytes(MetalBytesArgument)
    
    var string: String{
        switch self{
        case .texture(let arg): return arg.string
        case .buffer(let arg): return arg.string
        case .bytes(let arg): return arg.string
        }
    }
    var index: Int{
        switch self{
        case .texture(let arg): return arg.index!
        case .buffer(let arg): return arg.index!
        case .bytes(let arg): return arg.index!
        }
    }
}

public struct MetalTextureArgument{
    let type: String
    let access: String
    let name: String
    var index: Int?
    var string: String{
        var h = "texture2d<_TYPE_, access::_ACCESS_> _NAME_ [[texture(_INDEX_)]]"
        h = h.replacingOccurrences(of: "_TYPE_", with: type)
        h = h.replacingOccurrences(of: "_ACCESS_", with: access)
        h = h.replacingOccurrences(of: "_NAME_", with: name)
        h = h.replacingOccurrences(of: "_INDEX_", with: "\(index!)")
        return h
    }
    public init(type: String, access: String, name: String, index: Int?=nil) {
        self.type = type
        self.access = access
        self.name = name
        self.index = index
    }
}

public struct MetalBufferArgument{
    let space: String
    var type: String?
    let name: String
    var index: Int?
    let swiftType: Any.Type
    var swiftTypeToMetal: SwiftTypeToMetal{
        SwiftTypeToMetal(swiftType: swiftType,
                         metalType: type)
    }
    var string: String{
        var h = "_NAMESPACE_ _TYPE_* _NAME_ [[buffer(_INDEX_)]]"
        h = h.replacingOccurrences(of: "_NAMESPACE_", with: space)
        h = h.replacingOccurrences(of: "_TYPE_", with: type!)
        h = h.replacingOccurrences(of: "_NAME_", with: name)
        h = h.replacingOccurrences(of: "_INDEX_", with: "\(index!)")
        return h
    }
    init(swiftType: Any.Type, space: String, type: String?=nil, name: String, index: Int?=nil) {
        self.space = space
        self.type = type
        self.name = name
        self.index = index
        self.swiftType = swiftType
    }
    public init<T>(_ container: MTLBufferContainer<T>,
                    space: String, type: String?=nil, name: String?=nil, index: Int?=nil) throws{
        
        var t: String?
        if let type = container.metalType{
            t = type
        }
        if let type = type{
            t = type
        }
//        guard let type = t
//        else {
//            throw MetalBuilderFunctionArgumentsError
//                .bufferArgumentError("No Metal type for buffer!")
//        }
        
        var n: String?
        if let name = container.metalName{
            n = name
        }
        if let name = name{
            n = name
        }
        guard let name = n
        else {
            throw MetalBuilderFunctionArgumentsError
                .bufferArgumentError("No Metal name for buffer!")
        }

        self.init(swiftType: T.self, space: space, type: t, name: name, index: index)
    }
}

public struct MetalBytesArgument{
    let space: String
    var type: String?
    let name: String
    var index: Int?
    let swiftType: Any.Type
    let metalDeclaration: MetalTypeDeclaration?
    var swiftTypeToMetal: SwiftTypeToMetal{
        SwiftTypeToMetal(swiftType: swiftType,
                         metalType: type)
    }
    var string: String{
        var h = "_NAMESPACE_ _TYPE_& _NAME_ [[buffer(_INDEX_)]]"
        h = h.replacingOccurrences(of: "_NAMESPACE_", with: space)
        h = h.replacingOccurrences(of: "_TYPE_", with: type!)
        h = h.replacingOccurrences(of: "_NAME_", with: name)
        h = h.replacingOccurrences(of: "_INDEX_", with: "\(index!)")
        return h
    }
    init(swiftType: Any.Type, space: String, type: String?, name: String, index: Int?=nil, metalDeclaration: MetalTypeDeclaration?=nil) {
        self.swiftType = swiftType
        self.space = space
        self.type = type
        self.name = name
        self.index = index
        
        self.metalDeclaration = metalDeclaration
    }
    init<T>(binding: MetalBinding<T>, space: String, type: String?=nil, name: String?=nil, index: Int?=nil){
        var n: String
        if let name = name {
            n = name
        }else{
            n = binding.metalName!
        }
        var t: String?
        if let type = type {
            t = type
        }else{
            t = binding.metalType
        }
        
        self.init(swiftType: T.self, space: space, type: t, name: n, index: index)
    }
    init(uniformsContainer: UniformsContainer, name: String?){
        let type = uniformsContainer.metalType
        let metalDeclaration = uniformsContainer.metalDeclaration
        let metalName: String
        if let name = name{
            metalName = name
        }else{
            metalName = uniformsContainer.metalName!
        }
        self.init(swiftType: Any.self, space: "constant",
                  type: type, name: metalName, metalDeclaration: metalDeclaration)
    }
}
