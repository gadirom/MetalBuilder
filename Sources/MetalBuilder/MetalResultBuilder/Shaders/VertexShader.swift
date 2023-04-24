
import SwiftUI

public struct VertexShader: InternalShaderProtocol{
    
    var bufsAndArgs: [(BufferProtocol, MetalBufferArgument)] = []
    var bytesAndArgs: [(BytesProtocol, MetalBytesArgument)] = []
    var texsAndArgs: [(Texture, MetalTextureArgument)] = []
    
    var uniformsAndNames: [(UniformsContainer, String?)] = []
    
    /// Creates the VertexShader with the name and the raw Metal source code
    /// - Parameters:
    ///   - name: Name of the vertex shader function in your Metal code
    ///   - source: The source code of the vertex shader
    ///
    /// The code for the vertex shader should countain the shader function declaration
    /// along with the declaration of the Metal type that the shader outputs:
    /// ```
    /// let vertex = VertexShader("myVertexFunction", source:"""
    ///     struct VertexOut{
    ///         float4 pos [[position]];
    ///         float4 color;
    ///     };
    ///     vertex VertexOut myVertexFunction(uint vertex_id [[vertex_id]]){
    ///         Vertex v = vertexBuffer[vertex_id];
    ///         float3 pos3 = float3(v.pos, 1);
    ///         pos3 *= viewportToDeviceTransform;
    ///         VertexOut out;
    ///         out.pos = float4(pos3.xy, v.depth, 1);
    ///         out.color = v.color;
    ///         return out;
    ///     }
    ///""")
    ///```
    public init(_ name: String, source: String=""){
        self.vertexFunc = name
        self.source = source
        self.vertexOut = getTypeFromFromStructDeclaration(source)
    }
    /// Creates the VertexShader with the name and the raw Metal source code
    /// - Parameters:
    ///   - name: Name of the vertex shader function in your Metal code
    ///   - vertexOut: The declaration of the C-struct that the vertex shader outputs
    ///   - body: The source code of the vertex shader without declaration
    ///
    /// You pass only the body of the vertex function.
    /// MetalBuilder will generate the declaration automatically,
    /// passing the `vertex_id` property to the shader body:
    /// ```
    /// let vertex = VertexShader("myVertexFunction",
    ///       vertexOut:"""
    ///         struct VertexOut{
    ///         float4 pos [[position]];
    ///         float4 color;
    ///       };""",
    ///       body:"""
    ///         Vertex v = vertexBuffer[vertex_id];
    ///         float3 pos3 = float3(v.pos, 1);
    ///         pos3 *= viewportToDeviceTransform;
    ///         VertexOut out;
    ///         out.pos = float4(pos3.xy, v.depth, 1);
    ///         out.color = v.color;
    ///         return out;
    ///     """)
    ///```
    public init(_ name: String, vertexOut: String? = nil,
                body: String=""){
        self.vertexFunc = name
        self.vertexOutDeclaration = vertexOut
        if let vertexOut{
            self.vertexOut = getTypeFromFromStructDeclaration(vertexOut)
        }
        self.body = body
    }
    
    let vertexFunc: String
    var vertexOut: String?
    var vertexOutDeclaration: String?
    
    public var body: String?
    public var source: String?
    
    var librarySource: String{
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
public extension VertexShader{
    ///  Adds the declaration of the C-struct that used as output of the vertex shader
    /// - Parameter declaration: Declaration of the output type.
    /// - Returns: Vertex shader with the added declaration of output type.
    func vertexOut(_ declaration: String)->VertexShader{
        var v = self
        v.vertexOut = getTypeFromFromStructDeclaration(declaration)
        v.vertexOutDeclaration = declaration
        return v
    }
}
