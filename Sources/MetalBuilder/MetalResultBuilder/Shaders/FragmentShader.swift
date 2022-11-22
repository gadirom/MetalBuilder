
import SwiftUI

/// Fragment Shader that you pass to a Render component
///
/// All the uniforms that are passed to the Render component will be also available
/// in the Metal code of the shader function:
/// ```
/// Render()
///     .uniforms(uniforms)
///     .fragmentShader(fragment)
/// ```
/// You also may pass any uniforms, buffers or textures directly to the shaders using modifiers:
///```
/// Render()
///     .fragmentShader(
///         fragment
///             .texture(imageTexture)
///             .buffer(colorsBuffer)
///     )
/// ```
public struct FragmentShader: InternalShaderProtocol{
    
    var bufsAndArgs: [(BufferProtocol, MetalBufferArgument)] = []
    var bytesAndArgs: [(BytesProtocol, MetalBytesArgument)] = []
    var texsAndArgs: [(Texture, MetalTextureArgument)] = []
    
    var uniformsAndNames: [(UniformsContainer, String?)] = []
    
    /// Creates the Fragment Shader with the name and the raw Metal source code
    /// - Parameters:
    ///   - name: Name of the fragment shader function in your Metal code
    ///   - source: The source code of the Fragment shader that should countain a shader function declaration
    ///
    /// Example:
    /// ```
    /// let fragment = FragmentShader("myFragmetFunction", source:"""
    ///     fragment float4 myFragmetFunction(VertexOut in [[stage_in]],
    ///                                       float2 p [[point_coord]]){
    ///     return in.color;
    /// }
    /// """
    /// ```
    public init(_ name: String, source: String=""){
        self.fragmentFunc = name
        self.source = source
    }
    /// Creates the Fragment Shader with the name, return type and and the body of the fragment function
    /// - Parameters:
    ///   - name: Name of the fragment shader function in your Metal code
    ///   - returns: The Metal type the the fragment returns. Default type is `float4`.
    ///   - source: The body of the Fragment shader without the function declaration
    ///
    /// You pass only the body of the fragment function.
    /// MetalBuilder will generate the declaration automatically, passing the output of the vertex function as `in`:
    /// ```
    /// let fragment = FragmentShader("myFragmetFunction", body:"""
    ///     return in.color;
    /// """
    /// ```
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
