
import SwiftUI

public struct FragmentShader: InternalShaderProtocol{
    
    var bufsAndArgs: [(BufferProtocol, MetalBufferArgument)] = []
    var bytesAndArgs: [(BytesProtocol, MetalBytesArgument)] = []
    var texsAndArgs: [(Texture, MetalTextureArgument)] = []
    
    var uniformsAndNames: [(UniformsContainer, String?)] = []
    
    public init(_ name: String, source: String=""){
        self.fragmentFunc = name
        self.source = source
    }
    
    public init(_ name: String, returns: String="float4",
                body: String=""){
        self.fragmentFunc = name
        self.returnType = returns
        self.body = body
    }
    
    let fragmentFunc: String
    var returnType: String?
    
    public var body: String?
    public var source: String?
    
    func librarySource(vertexOut: String?) -> String{
        if let source = source{
            return source
        }
        if let body = body, let returns = returnType, let vertexOut = vertexOut{
            return "fragment "+returns+" "+fragmentFunc+"("+vertexOut+" in [[stage_in]]){"+body+"}"
        }
        print("Couldn't get the source code for ", fragmentFunc, " fragment shader!")
        return ""
    }
}
//FragmentShader's wrappers for ShaderProtocol modifiers
public extension FragmentShader{
    func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int, argument: MetalBufferArgument) -> FragmentShader{
        return _buffer(container, offset: offset, argument: argument) as! FragmentShader
    }
    func bytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument) -> FragmentShader{
        return _bytes(binding, argument: argument) as! FragmentShader
    }
    func bytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil, name: String?=nil, index: Int?=nil)->FragmentShader{
        return _bytes(binding, space: space, type: type, name: name, index: index) as! FragmentShader
    }
    func texture(_ container: MTLTextureContainer, argument: MetalTextureArgument) -> FragmentShader{
        return _texture(container, argument: argument) as! FragmentShader
    }
    func uniforms(_ uniforms: UniformsContainer, name: String?=nil) -> FragmentShader{
        return _uniforms(uniforms, name: name) as! FragmentShader
    }
    func source(_ source: String)->FragmentShader{
        return _source(source) as! FragmentShader
    }
    func body(_ body: String)->FragmentShader{
        return _body(body) as! FragmentShader
    }
}
