
import SwiftUI

public struct FragmentShader: ShaderProtocol{
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
/*
public extension FragmentShader{
    func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int, argument: MetalBufferArgument) -> FragmentShader{
        var f = self
        let buf = Buffer(container: container, offset: offset, index: 0)
        f.bufsAndArgs.append((buf, argument))
        return f
    }
    func bytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument) -> FragmentShader{
        var f = self
        let bytes = Bytes(binding: binding, index: 0)
        f.bytesAndArgs.append((bytes, argument))
        return f
    }
    func bytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil, name: String?=nil, index: Int?=nil)->FragmentShader{
        let argument = MetalBytesArgument(binding: binding, space: space, type: type, name: name)
        return bytes(binding.binding, argument: argument)
    }
    func texture(_ container: MTLTextureContainer, argument: MetalTextureArgument) -> FragmentShader{
        var f = self
        let tex = Texture(container: container, index: 0)
        f.texsAndArgs.append((tex, argument))
        return f
    }
    func uniforms(_ uniforms: UniformsContainer, name: String?=nil) -> FragmentShader{
        var f = self
        f.uniformsAndNames.append((uniforms, name))
        return f
    }
    func source(_ source: String)->FragmentShader{
        var f = self
        f.source = source
        return f
    }
    func body(_ body: String)->FragmentShader{
        var f = self
        f.body = body
        return f
    }
}
*/
