
import SwiftUI

public struct VertexShader: InternalShaderProtocol{
    
    var bufsAndArgs: [(BufferProtocol, MetalBufferArgument)] = []
    var bytesAndArgs: [(BytesProtocol, MetalBytesArgument)] = []
    var texsAndArgs: [(Texture, MetalTextureArgument)] = []
    
    var uniformsAndNames: [(UniformsContainer, String?)] = []
    
    public init(_ name: String, source: String=""){
        self.vertexFunc = name
        self.source = source
        self.vertexOut = VertexShader.getVertexOutTypeFromVertexSource(source)
    }
    
    public init(_ name: String, vertexOut: String="float4",
                body: String=""){
        self.vertexFunc = name
        self.vertexOut = vertexOut
        self.body = body
    }
    
    let vertexFunc: String
    var vertexOut: String?
    var vertexOutDeclaration: String?
    
    public var body: String?
    public var source: String?
    
    func librarySource(vertexOut: String?) -> String{
        if let source = source{
            return source
        }
        if let body = body, let vertexOut = vertexOut,
           let vertexOutDeclaration = vertexOutDeclaration{
            return vertexOutDeclaration+"vertex "+vertexOut+" "+vertexFunc+"(uint vertex_id [[vertex_id]]){"+body+"}"
        }
        print("Couldn't get the source code for ", vertexFunc, " vertex shader!")
        return ""
    }
    static func getVertexOutTypeFromVertexSource(_ source: String) ->String?{
        let structRange = source.range(of: "struct ")
        guard let startIndex = structRange?.upperBound
        else{ return nil }
        guard let endIndex = source[startIndex...].firstIndex(of: "{")
        else { return nil }

        return ""+source[startIndex...source.index(before: endIndex)]
    }
}

//VertexShader's wrappers for ShaderProtocol modifiers
public extension VertexShader{
    func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int, argument: MetalBufferArgument) -> VertexShader{
        return _buffer(container, offset: offset, argument: argument) as! VertexShader
    }
    func bytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument) -> VertexShader{
        return _bytes(binding, argument: argument) as! VertexShader
    }
    func bytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil, name: String?=nil, index: Int?=nil)->VertexShader{
        return _bytes(binding, space: space, type: type, name: name, index: index) as! VertexShader
    }
    func texture(_ container: MTLTextureContainer, argument: MetalTextureArgument) -> VertexShader{
        return _texture(container, argument: argument) as! VertexShader
    }
    func uniforms(_ uniforms: UniformsContainer, name: String?=nil) -> VertexShader{
        return _uniforms(uniforms, name: name) as! VertexShader
    }
    func source(_ source: String)->VertexShader{
        return _source(source) as! VertexShader
    }
    func body(_ body: String)->VertexShader{
        return _body(body) as! VertexShader
    }
}

//Modifiers specific to VertexShader
extension VertexShader{
    func vertexOut(_ type: String, properties: String)->VertexShader{
        var v = self
        v.vertexOut = type
        v.vertexOutDeclaration = "struct "+"vertexOut{"+properties+"};"
        return v
    }
}
