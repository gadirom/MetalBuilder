
import Foundation
import Metal

enum MetalBuilderFunctionArgumentsError: Error {
case bufferArgumentError(String), textureArgumentError(String)
}

public enum MetalFunctionArgument{
    case texture(MetalTextureArgument),
         buffer(MetalBufferArgument),
         bytes(MetalBytesArgument),
         instanceID
    
    func string() throws -> String{
        switch self{
        case .texture(let arg): return try arg.string()
        case .buffer(let arg): return arg.string
        case .bytes(let arg): return arg.string
        case .instanceID: return "uint instance_id [[instance_id]]"
        }
    }
    var index: Int{
        switch self{
        case .texture(let arg): return arg.index!
        case .buffer(let arg): return arg.index!
        case .bytes(let arg): return arg.index!
        case .instanceID: return -1 // no index for instanceID
        }
    }
}

/// Texture argument descriptor that you use to pass texture containers to Compute and Render components.
///
/// Typically you use a texture argument to tell MetalBuilder to create a Metal declaration for your shader:
///```
///Compute("myComputeKernel")
///      .texture(inTexture,
///               argument: .init(type: "float", access: "read", name: "in"))
///      .texture(outTexture,
///               argument: .init(type: "float", access: "write", name: "out"))
///```
public struct MetalTextureArgument{
    let type: String
    var textureType: MTLTextureType?=nil
    let access: String
    let name: String
    var index: Int?
    func string() throws -> String{
        var prefix = ""
        switch textureType!{
        case .type2D: prefix = "texture2d"
        case .type2DArray: prefix = "texture2d_array"
        case .type1D: prefix = "texture1d"
        case .type1DArray: prefix = "texture1d_array"
        case .type2DMultisample: prefix = "texture2d_ms"
        case .type2DMultisampleArray: prefix = "texture2d_ms_array"
        case .typeCube: prefix = "texturecube"
        case .typeCubeArray: prefix = "texturecube_array"
        case .type3D: prefix = "texture3d"
        //case .typeTextureBuffer: prefix = ""
        //case .none: prefix = ""
        //case .some(_): prefix =
        default: throw MetalBuilderFunctionArgumentsError
                .textureArgumentError("Unsupported texture type: "+String(describing: textureType))
        }
        var h = prefix+"<_TYPE_, access::_ACCESS_> _NAME_ [[texture(_INDEX_)]]"
        h = h.replacingOccurrences(of: "_TYPE_", with: type)
        h = h.replacingOccurrences(of: "_ACCESS_", with: access)
        h = h.replacingOccurrences(of: "_NAME_", with: name)
        h = h.replacingOccurrences(of: "_INDEX_", with: "\(index!)")
        return h
    }
    /// Creates a texture argument.
    /// - Parameters:
    ///   - type: The metal type of the pixels of the texture.
    ///   - access: The access attribute for the texture.
    ///   - name: The name of the variable by which the texture is passed to a shader.
    ///   - index: index of the texture in the shader declaration.
    /// If nil, the index will be set automatically by MetalBuilder.
    /// (Once you pass nil for the index of a texture argument of a component,
    /// avoid passing non-nil values in texture arguments of the same component.)
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
        if let type = metalType(for: T.self){
            t = type
        }
        if let type = container.metalType{
            t = type
        }
        if let type = type{
            t = type
        }
        
//        guard t != nil
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
