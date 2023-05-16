import MetalKit
import SwiftUI

enum MetalDSPRenderSetupError: Error{
    //case noGridFit(String)
}

public typealias AdditionalEncodeClosureForRender = (MTLRenderCommandEncoder)->()
public typealias AdditionalPiplineSetupClosureForRender = (MTLRenderPipelineState)->()
public typealias PiplineSetupClosureForRender = (MTLDevice, MTLLibrary)->(MTLRenderPipelineState)

/// The component for rendering primitives.
///
/// With this component you render points, triangles and lines on the screen.
/// (This is a wrapper for `.drawPrimitives` and `.drawIndexedPrimitives` of `MTLRenderPassEncoder`.)
/// You pass textures and buffers to the vertex or fragment functions
/// using modifiers like `.vertexTexture`, `.fragmentBuffer`, ect.
/// The uniforms containers are passed to both vertex and fragment functions via the single `.uniforms` modifier.
/// The Metal source code for the functions should be either provided in the `librarySource` parameter
/// of the init of `MetalBuilderView`, or via the `.source` modifier:
/// ```
///     MetalBuilderView(){
///         Render()
///             .vertexBuffer(particles) //passed a buffer to the vertex shader
///             .fragmentTexture(imageTexture) //passed a texture to the fragment shader
///             .uniforms(uniforms) //passed uniforms to both shaders
///             .source("""
///             ...//Your Metal shaders here
///             """)
///             .fragmentBytes($myParameter) //passed a value to the fragment shader
///     }
/// ```
/// You can also use the `FragmentShader` and `VertexShader` structs
/// to have more modularity in configuring your shaders.
/// Note that you may pass objects to the shaders directly or through the Render component:
/// ```
///     MetalBuilderView(){
///         Render()
///             .vertexShader(myVertexShader
///                 .buffer(particles) //a buffer passed directly to the vertex shader
///             )
///             .fragmentShader(myFragmentShader
///                 .texture(imageTexture) //a texture passed directly to the fragment shader
///                 .uniforms(myUniformsForFragment) //uniforms passed directly
///                                                  //to the fragment shader
///             )
///             .uniforms(uniforms) //uniforms passed to both shaders
///                                 //through the Render component
///             .fragmentBytes($myParameter) //a value passed to the fragment shader
///                                          //through the Render component
///     }
/// ```
public struct Render: MetalBuilderComponent, Renderable {
    
    var vertexFunc: String
    var fragmentFunc: String
    
    var librarySource: String
    var vertexOut: String?
    
    var type: MTLPrimitiveType!
    var vertexOffset: Int = 0
    var vertexCount: Int = 0
    
    var indexCount: MetalBinding<Int> = MetalBinding<Int>.constant(0)
    var indexBufferOffset: Int = 0
    var indexedPrimitives = false
    
    var additionalEncodeClosure: MetalBinding<AdditionalEncodeClosureForRender>?
    var additionalPiplineSetupClosure: MetalBinding<AdditionalPiplineSetupClosureForRender>?
    var piplineSetupClosure: MetalBinding<PiplineSetupClosureForRender>?
    
    var instanceCount: MetalBinding<Int>?{
        didSet {
            if instanceCount != nil{
                self.vertexArguments.append(MetalFunctionArgument.instanceID)
            }
        }
    }
    
    var indexBuf: BufferProtocol?
    
    var vertexBufs: [BufferProtocol] = []
    var vertexBytes: [BytesProtocol] = []
    var vertexTextures: [Texture] = []
    
    var fragBufs: [BufferProtocol] = []
    var fragBytes: [BytesProtocol] = []
    var fragTextures: [Texture] = []
    
    var vertexArguments: [MetalFunctionArgument] = []
    var fragmentArguments: [MetalFunctionArgument] = []
    
    var vertexBufferIndexCounter = 0
    var fragmentBufferIndexCounter = 0
    var vertexTextureIndexCounter = 0
    var fragmentTextureIndexCounter = 0
    
    public var renderableData = RenderableData()
    
    var uniforms: [UniformsContainer] = []
    
    public init(vertex: String="", fragment: String="", type: MTLPrimitiveType = .triangle,
                offset: Int = 0, count: Int = 3, source: String="",
                instanceCount: MetalBinding<Int>? = nil,
                renderableData: RenderableData = RenderableData()){
        self.vertexFunc = vertex
        self.fragmentFunc = fragment
        
        self.librarySource = source
        
        self.type = type
        self.vertexOffset = offset
        self.vertexCount = count
        self.renderableData = renderableData
        
        //Properties with didSet logic
        defer {
            self.instanceCount = instanceCount
        }
    }
    
    public init<T>(vertex: String="", fragment: String="", type: MTLPrimitiveType = .triangle,
                   indexBuffer: MTLBufferContainer<T>,
                   indexOffset: Int = 0, indexCount: MetalBinding<Int>, source: String="",
                   instanceCount: MetalBinding<Int>? = nil,
                   renderableData: RenderableData = RenderableData()){
        self.indexBuf = Buffer(container: indexBuffer, offset: 0, index: 0)
        
        self.vertexFunc = vertex
        self.fragmentFunc = fragment
        
        self.librarySource = source
        
        self.type = type
        
        self.indexCount = indexCount
        self.indexBufferOffset = indexOffset
        self.indexedPrimitives = true
        self.renderableData = renderableData
        
        //Properties with didSet logic
        defer {
            self.instanceCount = instanceCount
        }
    }
    
    mutating func setup() throws{
    }
}

//private non-generic chain modifiers
extension Render{
    func vertexBuf(_ buf: BufferProtocol, argument: MetalBufferArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkVertexBufferIndex(r: &r, index: argument.index)
        r.vertexArguments.append(MetalFunctionArgument.buffer(argument))
        var buf = buf
        buf.index = argument.index!
        r.vertexBufs.append(buf)
        return r
    }
    func vertexBytes(_ bytes: BytesProtocol, argument: MetalBytesArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkVertexBufferIndex(r: &r, index: argument.index)
        r.vertexArguments.append(.bytes(argument))
        var bytes = bytes
        bytes.index = argument.index!
        r.vertexBytes.append(bytes)
        return r
    }
    func vertexTexture(_ tex: Texture, argument: MetalTextureArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkVertexTextureIndex(r: &r, index: argument.index)
        argument.textureType = tex.container.descriptor.type
        r.vertexArguments.append(.texture(argument))
        var tex = tex
        tex.index = argument.index!
        r.vertexTextures.append(tex)
        return r
    }
    func fragBuf(_ buf: BufferProtocol, argument: MetalBufferArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkFragmentBufferIndex(r: &r, index: argument.index)
        r.fragmentArguments.append(.buffer(argument))
        var buf = buf
        buf.index = argument.index!
        r.fragBufs.append(buf)
        return r
    }
    func fragBytes(_ bytes: BytesProtocol, argument: MetalBytesArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkFragmentBufferIndex(r: &r, index: argument.index)
        r.fragmentArguments.append(.bytes(argument))
        var bytes = bytes
        bytes.index = argument.index!
        r.fragBytes.append(bytes)
        return r
    }
    func fragTexture(_ tex: Texture, argument: MetalTextureArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkVertexTextureIndex(r: &r, index: argument.index)
        argument.textureType = tex.container.descriptor.type
        r.fragmentArguments.append(.texture(argument))
        var tex = tex
        tex.index = argument.index!
        r.fragTextures.append(tex)
        return r
    }
}
// Buffer modifiers for Render
public extension Render{
    func vertexBuf<T>(_ container: MTLBufferContainer<T>, offset: Int = 0, index: Int)->Render{
        var r = self
        let buf = Buffer(container: container, offset: offset, index: index)
        r.vertexBufs.append(buf)
        return r
    }
    func vertexBuf<T>(_ container: MTLBufferContainer<T>, offset: Int = 0, argument: MetalBufferArgument)->Render{
        let buf = Buffer(container: container, offset: offset, index: 0)
        return self.vertexBuf(buf, argument: argument)
    }
    /// Passes a buffer to the vertex shader of a Render component.
    /// - Parameters:
    ///   - container: The buffer container.
    ///   - offset: The number of buffer elements to offset.
    ///   - space: The address space for this buffer, default is "constant".
    ///   - type: The optional Metal type of the elements of this buffer. If nil, the buffer's own `type` will be used.
    ///   - name: The optional name of the property that will be passed to the shader to access this buffer.
    ///   If nil, the buffer's own `name` will be used.
    /// - Returns: The Render component with the added buffer argument to the vertex shader.
    ///
    /// This method adds a buffer to the vertex shader of a Render component and parses the Metal library code,
    /// automatically adding an argument declaration to the vertex function.
    /// Use this modifier if you do not want to declare the function's argument manually.
    func vertexBuf<T>(_ container: MTLBufferContainer<T>, offset: Int = 0,
                      space: String = "constant", type: String?=nil, name: String?=nil) -> Render{
        
        let argument = try! MetalBufferArgument(container, space: space, type: type, name: name)
        
        return self.vertexBuf(container, offset: offset, argument: argument)
    }
    
    func fragBuf<T>(_ container: MTLBufferContainer<T>, offset: Int, index: Int)->Render{
        var r = self
        let buf = Buffer(container: container, offset: offset, index: index)
        r.fragBufs.append(buf)
        return r
    }
    func fragBuf<T>(_ container: MTLBufferContainer<T>, offset: Int, argument: MetalBufferArgument)->Render{
        let buf = Buffer(container: container, offset: offset, index: 0)
        return self.fragBuf(buf, argument: argument)
    }
    /// Passes a buffer to the fragment shader of a Render component.
    /// - Parameters:
    ///   - container: The buffer container.
    ///   - offset: The number of buffer elements to offset.
    ///   - space: The address space for this buffer, default is "constant".
    ///   - type: The optional Metal type of the elements of this buffer. If nil, the buffer's own `type` will be used.
    ///   - name: The optional name of the property that will be passed to the shader to access this buffer.
    ///   If nil, the buffer's own `name` will be used.
    /// - Returns: The Render component with the added buffer argument to the fragment shader.
    ///
    /// This method adds a buffer to the fragment shader of a Render component and parses the Metal library code,
    /// automatically adding an argument declaration to the fragment function.
    /// Use this modifier if you do not want to declare the function's argument manually.
    func fragBuf<T>(_ container: MTLBufferContainer<T>, offset: Int = 0,
                    space: String="constant", type: String?=nil, name: String?=nil) -> Render{
        
        let argument = try! MetalBufferArgument(container, space: space, type: type, name: name)
        
        return self.fragBuf(container, offset: offset, argument: argument)
        
    }
}
// Bytes modifiers for Render
public extension Render{
    func vertexBytes<T>(_ binding: Binding<T>, index: Int)->Render{
        var r = self
        let bytes = Bytes(binding: binding, index: index)
        r.vertexBytes.append(bytes)
        return r
    }
    func vertexBytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument)->Render{
        let bytes = Bytes(binding: binding, index: 0)
        return self.vertexBytes(bytes, argument: argument)
    }
    func vertexBytes<T>(_ binding: MetalBinding<T>, argument: MetalBytesArgument)->Render{
        self.vertexBytes(binding.binding, argument: argument)
    }
    /// Passes a value to the vertex shader of a Render component.
    /// - Parameters:
    ///   - binding: MetalBinding value created with the`@MetalState` property wrapper.
    ///   - space: The address space for this value, default is "constant".
    ///   - type: The optional Metal type of the value.
    ///   If nil, the value's own `type` will be used that is defined in `@MetalState` declaration for this value.
    ///   - name: The optional name of the property that will be passed to the shader to access this buffer.
    ///   If nil, the value's own `name` will be used that is defined in `@MetalState` declaration for this value.
    /// - Returns: The Render component with the added buffer argument to the vertex shader.
    ///
    /// This method adds a value to the vertex shader of a Render component and parses the Metal library code,
    /// automatically adding an argument declaration to the vertex function.
    /// Use this modifier if you do not want to declare the function's argument manually.
    func vertexBytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil, name: String?=nil, index: Int?=nil)->Render{
        let argument = MetalBytesArgument(binding: binding, space: space, type: type, name: name)
        return vertexBytes(binding, argument: argument)
    }
    /// Passes a value to the vertex shader of a Render component.
    /// - Parameters:
    ///   - binding: The SwiftUI's binding.
    ///   - space: The address space for this value, default is "constant".
    ///   - type: The optional Metal type of the value.
    ///   If nil, the value's own `type` will be used that is defined in `@State` declaration for this value.
    ///   - name: The optional name of the property that will be passed to the shader to access this buffer.
    ///   If nil, the value's own `name` will be used that is defined in `@State` declaration for this value.
    /// - Returns: The Render component with the added buffer argument to the vertex shader.
    ///
    /// This method adds a value to the vertex shader of a Render component and parses the Metal library code,
    /// automatically adding an argument declaration to the vertex function.
    /// Use this modifier if you do not want to declare the function's argument manually.
    func vertexBytes<T>(_ binding: Binding<T>, space: String = "constant", type: String?=nil, name: String, index: Int?=nil)->Render{
        let metalBinding = MetalBinding(binding: binding, metalType: type, metalName: name)
        let argument = MetalBytesArgument(binding: metalBinding, space: space, type: type, name: name)
        return vertexBytes(binding, argument: argument)
    }
    func fragBytes<T>(_ binding: Binding<T>, index: Int)->Render{
        var r = self
        let bytes = Bytes(binding: binding, index: index)
        r.fragBytes.append(bytes)
        return r
    }
    func fragBytes<T>(_ binding: MetalBinding<T>, argument: MetalBytesArgument)->Render{
        let bytes = Bytes(binding: binding.binding, index: 0)
        return self.fragBytes(bytes, argument: argument)
    }
    func fragBytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkFragmentBufferIndex(r: &r, index: argument.index)
        r.fragmentArguments.append(.bytes(argument))
        let bytes = Bytes(binding: binding, index: argument.index!)
        r.fragBytes.append(bytes)
        return r
    }
    /// Passes a value to the fargment shader of a Render component.
    /// - Parameters:
    ///   - binding: MetalBinding value created with the`@MetalState` property wrapper.
    ///   - space: The address space for this value, default is "constant".
    ///   - type: The optional Metal type of the value.
    ///   If nil, the value's own `type` will be used that is defined in `@MetalState` declaration for this value.
    ///   - name: The optional name of the property that will be passed to the shader to access this buffer.
    ///   If nil, the value's own `name` will be used that is defined in `@MetalState` declaration for this value.
    /// - Returns: The Render component with the added buffer argument to the fargment shader.
    ///
    /// This method adds a value to the fargment shader of a Render component and parses the Metal library code,
    /// automatically adding an argument declaration to the fargment function.
    /// Use this modifier if you do not want to declare the function's argument manually.
    func fragBytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil, name: String?=nil, index: Int?=nil)->Render{
        let argument = MetalBytesArgument(binding: binding, space: space, type: type, name: name)
        return fragBytes(binding, argument: argument)
    }
    /// Passes a value to the fragment shader of a Render component.
    /// - Parameters:
    ///   - binding: The SwiftUI's binding.
    ///   - space: The address space for this value, default is "constant".
    ///   - type: The optional Metal type of the value.
    ///   If nil, the value's own `type` will be used that is defined in `@State` declaration for this value.
    ///   - name: The optional name of the property that will be passed to the shader to access this buffer.
    ///   If nil, the value's own `name` will be used that is defined in `@State` declaration for this value.
    /// - Returns: The Render component with the added buffer argument to the fragment shader.
    ///
    /// This method adds a value to the fragment shader of a Render component and parses the Metal library code,
    /// automatically adding an argument declaration to the fragment function.
    /// Use this modifier if you do not want to declare the function's argument manually.
    func fragBytes<T>(_ binding: Binding<T>, space: String = "constant", type: String?=nil, name: String, index: Int?=nil)->Render{
        let metalBinding = MetalBinding(binding: binding, metalType: type, metalName: name)
        let argument = MetalBytesArgument(binding: metalBinding, space: space, type: type, name: name)
        return fragBytes(binding, argument: argument)
    }
}
// Uniforms modifiers for Render
public extension Render{
    /// Adds a uniforms container to vertex and fragment shaders of the Render component.
    /// - Parameters:
    ///   - uniforms: The uniforms container.
    ///   - name: The name by which the uniforms container will be accessed in the shader functions.
    /// - Returns: The render component with the added uniforms container.
    func uniforms(_ uniforms: UniformsContainer, name: String?=nil) -> Render{
        var r = self
        r.uniforms.append(uniforms)
        var argument = MetalBytesArgument(uniformsContainer: uniforms, name: name)
        //Add to vertex shader
        argument.index = checkVertexBufferIndex(r: &r, index: nil)
        r.vertexArguments.append(.bytes(argument))
        let vertexBytes = RawBytes(binding: uniforms.pointerBinding,
                                   length: uniforms.length,
                                   index: argument.index!)
        r.vertexBytes.append(vertexBytes)
        //add to fragment shader
        argument.index = checkFragmentBufferIndex(r: &r, index: nil)
        r.fragmentArguments.append(.bytes(argument))
        let fragBytes = RawBytes(binding: uniforms.pointerBinding,
                                 length: uniforms.length,
                                 index: argument.index!)
        r.fragBytes.append(fragBytes)
        
        return r
    }
}
// Texture modifiers for Render
public extension Render{
    func vertexTexture(_ container: MTLTextureContainer, index: Int)->Render{
        var r = self
        let tex = Texture(container: container, index: index)
        r.vertexTextures.append(tex)
        return r
    }
    /// Passes a texture to the vertex shader of a Render component.
    /// - Parameters:
    ///   - container: The texture container.
    ///   - argument: The texture argument describing the declaration that should be added to the shader.
    /// - Returns: The Render component with the added texture argument.
    ///
    /// This method adds a texture to vertex shader of a Render component and parses the Metal library code,
    /// automatically adding an argument declaration to the vertex shader.
    /// Use this modifier if you do not want to declare the shader's argument manually.
    func vertexTexture(_ container: MTLTextureContainer, argument: MetalTextureArgument)->Render{
        let tex = Texture(container: container, index: 0)
        return self.vertexTexture(tex, argument: argument)
    }
    func fragTexture(_ container: MTLTextureContainer, index: Int)->Render{
        var r = self
        let tex = Texture(container: container, index: index)
        r.fragTextures.append(tex)
        return r
    }
    /// Passes a texture to the fragment shader of a Render component.
    /// - Parameters:
    ///   - container: The texture container.
    ///   - argument: The texture argument describing the declaration that should be added to the shader.
    /// - Returns: The Render component with the added texture argument.
    ///
    /// This method adds a texture to fragment shader of a Render component and parses the Metal library code,
    /// automatically adding an argument declaration to the fragment shader.
    /// Use this modifier if you do not want to declare the shader's argument manually.
    func fragTexture(_ container: MTLTextureContainer, argument: MetalTextureArgument)->Render{
        let tex = Texture(container: container, index: 0)
        return self.fragTexture(tex, argument: argument)
    }
}

// Misc modifiers for Render
public extension Render{
    /// The modifier for passing the source code of vertex and fragment shaders to a Render component
    /// - Parameter source: The String containing the code
    /// - Returns: The Render component with the added source code.
    ///
    /// The source code should obey the following structure:
    /// - 1. declaration of the vertex shader's output C-structure
    /// - 2. vertex shader implementation
    /// - 3. fragment shader implementation
    /// The first two or the last one should be ommited in case you are planning
    /// to pass the respective code using `.vertexShader`  or`.fragmentShader` modifiers.
    /// If you need to declare the output type for fragment shader declare it in `helpers` or consider using dedicated ``FragmentShader``.
    func source(_ source: String)->Render{
        var r = self
        r.librarySource = source + r.librarySource
        r.vertexOut = getTypeFromFromStructDeclaration(source)
        return r
    }
    func instanceCount(_ count: MetalBinding<Int>)->Render{
        var r = self
        r.instanceCount = count
        return r
    }
    /// Modifier for setting a closure for pipeline setup for Render component.
    /// - Parameter closureBinding: MetalBinding to a closure for pipeline setup logic.
    /// - Returns: Render component with the added custom pipeline setup logic.
    ///
    /// Use this modifier if you want to create MTLRenderPipelineState manually.
    func pipelineSetup(_ closureBinding: MetalBinding<PiplineSetupClosureForRender>)->Render{
        var r = self
        r.piplineSetupClosure = closureBinding
        return r
    }
    /// Modifier for setting a closure for pipeline setup for Render component.
    /// - Parameter closure: closure for custom pipeline setup logic.
    /// - Returns: Render component with the added custom pipeline setup logic.
    ///
    /// Use this modifier if you want to create MTLRenderPipelineState manually.
    func pipelineSetup(_ closure: @escaping PiplineSetupClosureForRender)->Render{
        self.pipelineSetup(MetalBinding<PiplineSetupClosureForRender>.constant(closure))
    }
    /// Modifier for setting a closure for additional pipeline setup for Render component.
    /// - Parameter closureBinding: MetalBinding to a closure for additional pipeline setup logic.
    /// - Returns: Render component with the added additional pipeline setup logic.
    ///
    /// The closure provided in this modifier will run after all the internal pipeline setup logic is performed.
    func additionalPipelineSetup(_ closureBinding: MetalBinding<AdditionalPiplineSetupClosureForRender>)->Render{
        var r = self
        r.additionalPiplineSetupClosure = closureBinding
        return r
    }
    /// Modifier for setting a closure for additional pipeline setup for Render component.
    /// - Parameter closure: closure for additional pipeline setup logic.
    /// - Returns: Render component with the added additional pipeline setup logic.
    ///
    /// The closure provided in this modifier will run after all the internal pipeline setup logic is performed.
    func additionalPipelineSetup(_ closure: @escaping AdditionalPiplineSetupClosureForRender)->Render{
        self.additionalPipelineSetup( MetalBinding<AdditionalPiplineSetupClosureForRender>.constant(closure))
    }
    /// Modifier for setting additional encode closure for Render component.
    /// - Parameter closureBinding: MetalBinding to a closure for additional encode logic.
    /// - Returns: Render component with the added additional encode logic.
    ///
    /// The closure provided in this modifier will run after all the internal encoding is performed
    /// right before the dispatch or before encoding of the next component.
    func additionalEncode(_ closureBinding: MetalBinding<AdditionalEncodeClosureForRender>)->Render{
        var r = self
        r.additionalEncodeClosure = closureBinding
        return r
    }
    /// Modifier for setting additional encode closure for Render component.
    /// - Parameter closure: Closure for additional encode logic.
    /// - Returns: Render component with the added additional encode logic.
    ///
    /// The closure provided in this modifier will run after all the internal encoding is performed
    /// right before the dispatch or before encoding of the next component.
    func additionalEncode(_ closure: @escaping AdditionalEncodeClosureForRender)->Render{
        self.additionalEncode(MetalBinding<AdditionalEncodeClosureForRender>.constant(closure))
    }
}
// Shader modifiers for Render
public extension Render{
    func vertexShader(_ shader: VertexShader)->Render{
        var r = self
        //func
        r.vertexFunc = shader.vertexFunc
        //vertexOut
        r.vertexOut = shader.vertexOut
        //source
        r.librarySource = shader.librarySource + librarySource
        //arguments
        return r.addShaderArguments(shader)
    }
    /// Adds the fragment shader to a Rnder component.
    /// - Parameter shader: Fragment shader that you want to use with Render.
    /// - Returns: The Render component with the added fragment shader.
    func fragmentShader(_ shader: FragmentShader)->Render{
        var r = self
        //func
        r.fragmentFunc = shader.fragmentFunc
        //source
        r.librarySource += shader.librarySource(vertexOut: vertexOut)
        //arguments
        return r.addShaderArguments(shader)
    }
}

//Internal utils for Render
extension Render{
    func addShaderArguments(_ sh: InternalShaderProtocol)->Render{
        var r = self
        //add buffer
        for bufAndArg in sh.bufsAndArgs{
            r = r.fragBuf(bufAndArg.0, argument: bufAndArg.1)
        }
        //add bytes
        for byteAndArg in sh.bytesAndArgs{
            r = r.fragBytes(byteAndArg.0, argument: byteAndArg.1)
        }
        //add textures
        for texAndArg in sh.texsAndArgs{
            r = r.fragTexture(texAndArg.0, argument: texAndArg.1)
        }
        //uniforms
        for uAndName in sh.uniformsAndNames{
            r = r.uniforms(uAndName.0, name: uAndName.1)
        }
        return r
    }
    func checkVertexBufferIndex(r: inout Render, index: Int?) -> Int{
        if index == nil {
            let index = vertexBufferIndexCounter
            r.vertexBufferIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
    func checkVertexTextureIndex(r: inout Render, index: Int?) -> Int{
        if index == nil {
            let index = vertexTextureIndexCounter
            r.vertexTextureIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
    func checkFragmentBufferIndex(r: inout Render, index: Int?) -> Int{
        if index == nil {
            let index = fragmentBufferIndexCounter
            r.fragmentBufferIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
    func checkFragmentTextureIndex(r: inout Render, index: Int?) -> Int{
        if index == nil {
            let index = fragmentTextureIndexCounter
            r.fragmentTextureIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
}
