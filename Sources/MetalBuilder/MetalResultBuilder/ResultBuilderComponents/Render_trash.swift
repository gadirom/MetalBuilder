
//VertexShader's wrappers for ShaderProtocol modifiers
public extension VertexShader{
//    func buffer<T>(_ container: MTLBufferContainer<T>, offset: MetalBinding<Int>, argument: MetalBufferArgument) -> VertexShader{
//        return _buffer(container, offset: offset, argument: argument) as! VertexShader
//    }
//    func bytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument) -> VertexShader{
//        return _bytes(binding, argument: argument) as! VertexShader
//    }
//    func bytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil, name: String?=nil, index: Int?=nil)->VertexShader{
//        return _bytes(binding, space: space, type: type, name: name, index: index) as! VertexShader
//    }
//    func texture(_ container: MTLTextureContainer, argument: MetalTextureArgument) -> VertexShader{
//        return _texture(container, argument: argument) as! VertexShader
//    }
//    func uniforms(_ uniforms: UniformsContainer, name: String?=nil) -> VertexShader{
//        return _uniforms(uniforms, name: name) as! VertexShader
//    }
//    func source(_ source: String)->VertexShader{
//        return _source(source) as! VertexShader
//    }
//    func body(_ body: String)->VertexShader{
//        return _body(body) as! VertexShader
//    }
}
//private non-generic chain modifiers
/*
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
    func vertexBuf<T>(_ container: MTLBufferContainer<T>,
                      offset: MetalBinding<Int> = .constant(0),
                      index: Int)->Render{
        var r = self
        let buf = Buffer(container: container, offset: offset, index: index)
        r.vertexBufs.append(buf)
        return r
    }
    func vertexBuf<T>(_ container: MTLBufferContainer<T>,
                      offset: MetalBinding<Int> = .constant(0),
                      argument: MetalBufferArgument)->Render{
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
    func vertexBuf<T>(_ container: MTLBufferContainer<T>, offset: MetalBinding<Int> = .constant(0),
                      space: String = "constant", type: String?=nil, name: String?=nil) -> Render{
        
        let argument = try! MetalBufferArgument(container, space: space, type: type, name: name, index: nil)
        
        return self.vertexBuf(container, offset: offset, argument: argument)
    }
    
    func fragBuf<T>(_ container: MTLBufferContainer<T>, offset: MetalBinding<Int> = .constant(0),
                    index: Int)->Render{
        var r = self
        let buf = Buffer(container: container, offset: offset, index: index)
        r.fragBufs.append(buf)
        return r
    }
    func fragBuf<T>(_ container: MTLBufferContainer<T>, offset: MetalBinding<Int> = .constant(0),
                    argument: MetalBufferArgument)->Render{
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
    func fragBuf<T>(_ container: MTLBufferContainer<T>, offset: MetalBinding<Int> = .constant(0),
                    space: String="constant", type: String?=nil, name: String?=nil) -> Render{
        
        let argument = try! MetalBufferArgument(container, space: space, type: type, name: name, index: nil)
        
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
 }
*/
