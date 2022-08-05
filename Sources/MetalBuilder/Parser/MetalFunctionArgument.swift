
import Foundation

enum MetalBuilderFunctionArgumentsError: Error {
case bufferArgumentError(String), textureArgumentError(String)
}

public enum MetalFunctionArgument{
    case texture(MetalTextureArgument), buffer(MetalBufferArgument), bytes(MetalBytesArgument)
    
    var string: String{
        switch self{
        case .texture(let p): return p.string
        case .buffer(let p): return p.string
        case .bytes(let p): return p.string
        }
    }
    var index: Int{
        switch self{
        case .texture(let p): return p.index
        case .buffer(let p): return p.index
        case .bytes(let p): return p.index
        }
    }
}

public struct MetalTextureArgument{
    let type: String
    let access: String
    let name: String
    let index: Int
    var string: String{
        var h = "texture2d<_TYPE_, access::_ACCESS_> _NAME_ [[texture(_INDEX_)]]"
        h = h.replacingOccurrences(of: "_TYPE_", with: type)
        h = h.replacingOccurrences(of: "_ACCESS_", with: access)
        h = h.replacingOccurrences(of: "_NAME_", with: name)
        h = h.replacingOccurrences(of: "_INDEX_", with: "\(index)")
        return h
    }
    public init(type: String, access: String, name: String, index: Int) {
        self.type = type
        self.access = access
        self.name = name
        self.index = index
    }
}

public struct MetalBufferArgument{
    let space: String
    let type: String
    let name: String
    let index: Int
    var string: String{
        var h = "_NAMESPACE_ _TYPE_* _NAME_ [[buffer(_INDEX_)]]"
        h = h.replacingOccurrences(of: "_NAMESPACE_", with: space)
        h = h.replacingOccurrences(of: "_TYPE_", with: type)
        h = h.replacingOccurrences(of: "_NAME_", with: name)
        h = h.replacingOccurrences(of: "_INDEX_", with: "\(index)")
        return h
    }
    public init(space: String, type: String, name: String, index: Int) {
        self.space = space
        self.type = type
        self.name = name
        self.index = index
    }
    public init<T>(_ container: MTLBufferContainer<T>,
                    space: String, type: String?=nil, name: String?=nil, index: Int) throws{
        
        var t: String?
        if let type = container.metalType{
            t = type
        }
        if let type = type{
            t = type
        }
        guard let type = t
        else {
            throw MetalBuilderFunctionArgumentsError
                .bufferArgumentError("No Metal type for buffer!")
        }
        
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

        self.init(space: space, type: type, name: name, index: index)
    }
}

public struct MetalBytesArgument{
    let space: String
    let type: String
    let name: String
    let index: Int
    var string: String{
        var h = "_NAMESPACE_ _TYPE_& _NAME_ [[buffer(_INDEX_)]]"
        h = h.replacingOccurrences(of: "_NAMESPACE_", with: space)
        h = h.replacingOccurrences(of: "_TYPE_", with: type)
        h = h.replacingOccurrences(of: "_NAME_", with: name)
        h = h.replacingOccurrences(of: "_INDEX_", with: "\(index)")
        return h
    }
    public init(space: String, type: String, name: String, index: Int) {
        self.space = space
        self.type = type
        self.name = name
        self.index = index
    }
}
