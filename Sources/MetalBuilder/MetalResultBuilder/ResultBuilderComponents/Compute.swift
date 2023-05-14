
import MetalKit
import SwiftUI

enum GridFit{
    case fitTexture(MTLTextureContainer),
         size(Binding<MTLSize>),
         size1D(MetalBinding<Int>),
         drawable,
         buffer(Int)
}

public typealias AdditionalEncodeClosureForCompute = (MTLComputeCommandEncoder)->()

/// The component for dispatching compute kernels.
public struct Compute: MetalBuilderComponent{
    
    let kernel: String
    var buffers: [BufferProtocol] = []
    var bytes: [BytesProtocol] = []
    var textures: [Texture] = []
    
    var drawableTextureIndex: Int?
    var gridFit: GridFit?
    
    var kernelArguments: [MetalFunctionArgument] = []
    
    var bufferIndexCounter = 0
    var textureIndexCounter = 0
    
    var uniforms: [UniformsContainer] = []
    
    var librarySource: String = ""
    
    var additionalEncodeClosure: MetalBinding<AdditionalEncodeClosureForCompute>?
    
    public init(_ kernel: String, source: String = ""){
        self.kernel = kernel
    }
    
    mutating func setup() throws{
        if gridFit == nil{
            if let texture = textures.first{
                gridFit = .fitTexture(texture.container)
            }else{
                if drawableTextureIndex != nil{
                    gridFit = .drawable
                }else{
                    throw MetalBuilderComputeError
                    .noGridFit("No information for threads dispatching was set for the kernel: "+kernel+"\nUse 'grid' modifier or set index for drawable!")
                }
            }
        }
    }
}

// chaining functions for result builder
public extension Compute{
    /// Passes a buffer to the compute kernel.
    /// - Parameters:
    ///   - container: The buffer container.
    ///   - offset: The number of buffer elements to offset.
    ///   - index: Buffer index in kernel arguments.
    /// - Returns: The Compute component with the added buffer argument.
    ///
    /// This method adds a buffer to the compute function and doesn't change the Metal library code.
    /// Use it if you want to declare the kernel's argument manually.
    func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int = 0, index: Int)->Compute{
        var c = self
        let buf = Buffer(container: container, offset: offset, index: index)
        c.buffers.append(buf)
        return c
    }
    /// Passes a buffer to the compute kernel.
    /// - Parameters:
    ///   - container: The buffer container.
    ///   - offset: The number of buffer elements to offset.
    ///   - argument: The buffer argument describing the declaration that should be added to the kernel.
    ///   - fitThreads: Indicates if the threads dispatched for the compute kernel should be calculated
    /// from the size of this buffer.
    /// - Returns: The Compute component with the added buffer argument.
    ///
    /// This method adds a buffer to the compute function and parses the Metal library code,
    /// automatically adding an argument declaration to the kernel function.
    /// Use this modifier if you do not want to declare the kernel's argument manually.
    func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int = 0, argument: MetalBufferArgument, fitThreads: Bool=false)->Compute{
        var c = self
        var argument = argument
        argument.index = checkBufferIndex(c: &c, index: argument.index)
        c.kernelArguments.append(.buffer(argument))
        let buf = Buffer(container: container, offset: offset, index: argument.index!)
        c.buffers.append(buf)
        if fitThreads{
            c.gridFit = .buffer(argument.index!)
        }
        return c
    }
    /// Passes a buffer to the compute kernel.
    /// - Parameters:
    ///   - container: The buffer container.
    ///   - offset: The number of buffer elements to offset.
    ///   - space: The address space for this buffer, default is "constant".
    ///   - type: The optional Metal type of the elements of this buffer.If nil, the buffer's own `type` will be used.
    ///   - name: The optional name of the property that will be passed to the shader to access this buffer.
    ///   If nil, the buffer's own `name` will be used.
    ///   - fitThreads: Indicates if the threads dispatched for the compute kernel should be calculated
    /// from the size of this buffer.
    /// - Returns: The Compute component with the added buffer argument.
    ///
    /// This method adds a buffer to the compute function and parses the Metal library code,
    /// automatically adding an argument declaration to the kernel function.
    /// Use this modifier if you do not want to declare the kernel's argument manually.
    func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int = 0,
                   space: String="constant", type: String?=nil, name: String?=nil, fitThreads: Bool=false) -> Compute{
        
        let argument = try! MetalBufferArgument(container, space: space, type: type, name: name)
        return self.buffer(container, offset: offset, argument: argument, fitThreads: fitThreads)
    }
    func bytes<T>(_ binding: Binding<T>, index: Int)->Compute{
        var c = self
        let bytes = Bytes(binding: binding, index: index)
        c.bytes.append(bytes)
        return c
    }
    func bytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument)->Compute{
        var c = self
        var argument = argument
        argument.index = checkBufferIndex(c: &c, index: argument.index)
        c.kernelArguments.append(.bytes(argument))
        let bytes = Bytes(binding: binding, index: argument.index!)
        c.bytes.append(bytes)
        return c
    }
    func bytes<T>(_ binding: MetalBinding<T>, argument: MetalBytesArgument)->Compute{
        var c = self
        var argument = argument
        argument.index = checkBufferIndex(c: &c, index: argument.index)
        c.kernelArguments.append(.bytes(argument))
        let bytes = Bytes(binding: binding.binding, index: argument.index!)
        c.bytes.append(bytes)
        return c
    }
    /// Passes a value to the compute kernel of a Compute component.
    /// - Parameters:
    ///   - binding: MetalBinding value created with the`@MetalState` property wrapper.
    ///   - space: The address space for this value, default is "constant".
    ///   - type: The optional Metal type of the value.
    ///   If nil, the value's own `type` will be used that is defined in `@MetalState` declaration for this value.
    ///   - name: The optional name of the property that will be passed to the shader to access this buffer.
    ///   If nil, the value's own `name` will be used that is defined in `@MetalState` declaration for this value.
    /// - Returns: The Render component with the added buffer argument to the compute kernel.
    ///
    /// This method adds a value to the  compute kernel of a Compute component and parses the Metal library code,
    /// automatically adding an argument declaration to the  compute kernel.
    /// Use this modifier if you do not want to declare the function's argument manually.
    func bytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil, name: String?=nil, index: Int?=nil)->Compute{
        let argument = MetalBytesArgument(binding: binding, space: space, type: type, name: name, index: index)
        return bytes(binding, argument: argument)
    }
    /// Passes a value to the compute kernel of a Compute component.
    /// - Parameters:
    ///   - binding: The SwiftUI's binding.
    ///   - space: The address space for this value, default is "constant".
    ///   - type: The optional Metal type of the value.
    ///   If nil, the value's own `type` will be used that is defined in `@State` declaration for this value.
    ///   - name: The optional name of the property that will be passed to the shader to access this value.
    ///   If nil, the value's own `name` will be used that is defined in `@State` declaration for this value.
    /// - Returns: The Compute component with the added buffer argument to the compute kernel.
    ///
    /// This method adds a value to the compute kernel of a Compute component and parses the Metal library code,
    /// automatically adding an argument declaration to the compute kernel.
    /// Use this modifier if you do not want to declare the function's argument manually.
    func bytes<T>(_ binding: Binding<T>, space: String = "constant", type: String?=nil, name: String, index: Int?=nil)->Compute{
        let metalBinding = MetalBinding(binding: binding, metalType: type, metalName: name)
        let argument = MetalBytesArgument(binding: metalBinding, space: space, type: type, name: name, index: index)
        return bytes(binding, argument: argument)
    }
    func uniforms(_ uniforms: UniformsContainer, name: String?=nil) -> Compute{
        var c = self
        c.uniforms.append(uniforms)
        var argument = MetalBytesArgument(uniformsContainer: uniforms, name: name)
        argument.index = checkBufferIndex(c: &c, index: nil)
        c.kernelArguments.append(.bytes(argument))
        let bytes = RawBytes(binding: uniforms.pointerBinding,
                             length: uniforms.length,
                             index: argument.index!)
        c.bytes.append(bytes)
        return c
    }
    /// Passes a texture to the compute kernel.
    /// - Parameters:
    ///   - container: The texture container.
    ///   - index: The texture index in the kernel arguments.
    /// - Returns: The Compute component with the added texture argument.
    ///
    /// This method adds a texture to the compute function and doesn't change Metal library code.
    /// Use it if you want to declare the kernel's argument manually.
    func texture(_ container: MTLTextureContainer, index: Int)->Compute{
        var c = self
        let tex = Texture(container: container, index: index)
        c.textures.append(tex)
        return c
    }
    /// Passes a texture to the compute kernel.
    /// - Parameters:
    ///   - container: The texture container.
    ///   - argument: The texture argument describing the declaration that should be added to the kernel.
    ///   - fitThreads: Indicates if the threads dispatched for the compute kernel should be calculated
    /// from the size of this texture.
    /// - Returns: The Compute component with the added texture argument.
    ///
    /// This method adds a texture to the compute function and parses the Metal library code,
    /// automatically adding an argument declaration to the kernel function.
    /// Use this modifier if you do not want to declare the kernel's argument manually.
    func texture(_ container: MTLTextureContainer, argument: MetalTextureArgument, fitThreads: Bool=false)->Compute{
        var c = self
        var argument = argument
        argument.index = checkTextureIndex(c: &c, index: argument.index)
        argument.textureType = container.descriptor.type
        c.kernelArguments.append(.texture(argument))
        let tex = Texture(container: container, index: argument.index!)
        c.textures.append(tex)
        if fitThreads{
            c.gridFit = .fitTexture(container)
        }
        return c
    }
    /// Passes a drawable texture to the compute kernel.
    /// - Parameters:
    ///   - index: The texture index in the kernel arguments.
    /// - Returns: The Compute component with the added drawable texture argument.
    ///
    /// This method adds a drawable texture to the compute function and doesn't change Metal library code.
    /// Use it if you want to declare the kernel's argument manually.
    func drawableTexture(index: Int)->Compute{
        var c = self
        c.drawableTextureIndex = index
        c.gridFit = .drawable
        return c
    }
    /// Passes a drawable texture to the compute kernel.
    /// - Parameters:
    ///   - argument: The texture argument describing the declaration that should be added to the kernel.
    ///   - fitThreads: Indicates whether the threads for the kernel should be dispatched to fit the drawable texture.
    ///
    /// This method adds a drawable texture to the compute function and parses the Metal library code,
    /// automatically adding an argument declaration to the kernel function.
    /// Use this modifier if you do not want to declare the kernel's argument manually.
    func drawableTexture(argument: MetalTextureArgument, fitThreads: Bool = true)->Compute{
        var c = self
        var argument = argument
        argument.index = checkTextureIndex(c: &c, index: argument.index)
        argument.textureType = .type2D
        c.kernelArguments.append(.texture(argument))
        c.drawableTextureIndex = argument.index
        if fitThreads{
            c.gridFit = .drawable
        }
        return c
    }
    func grid(size: MetalBinding<Int>)->Compute{
        var c = self
        c.gridFit = .size1D(size)
        return c
    }
    func grid(size: Int)->Compute{
        var c = self
        c.gridFit = .size1D(MetalBinding<Int>.constant(size))
        return c
    }
    func grid(size: Binding<MTLSize>)->Compute{
        var c = self
        c.gridFit = .size(size)
        return c
    }
    func grid(fitTexture: MTLTextureContainer)->Compute{
        var c = self
        c.gridFit = .fitTexture(fitTexture)
        return c
    }
    func gridFitDrawable()->Compute{
        var c = self
        c.gridFit = .drawable
        return c
    }
    func threadsFromBuffer(_ index: Int)->Compute{
        var c = self
        c.gridFit = .buffer(index)
        return c
    }
    func source(_ source: String)->Compute{
        var c = self
        c.librarySource = source
        return c
    }
    /// Modifier for setting additional encode closure for Render component.
    /// - Parameter closureBinding: MetalBinding to a closure for additional encode logic.
    /// - Returns: Render component with the added additional encode logic.
    ///
    /// The closure provided in this modifier will run after all the internal encoding is performed
    /// right before the dispatch or before encoding of the next component.
    func additionalEncode(_ closureBinding: MetalBinding<AdditionalEncodeClosureForCompute>)->Compute{
        var c = self
        c.additionalEncodeClosure = closureBinding
        return c
    }
    /// Modifier for setting additional encode closure for Render component.
    /// - Parameter closure: Closure for additional encode logic.
    /// - Returns: Render component with the added additional encode logic.
    ///
    /// The closure provided in this modifier will run after all the internal encoding is performed
    /// right before the dispatch or before encoding of the next component.
    func additionalEncode(_ closure: @escaping AdditionalEncodeClosureForCompute)->Compute{
        var c = self
        c.additionalEncodeClosure = MetalBinding<AdditionalEncodeClosureForCompute>.constant(closure)
        return c
    }
}

extension Compute{
    func checkBufferIndex(c: inout Compute, index: Int?) -> Int{
        if index == nil {
            let index = bufferIndexCounter
            c.bufferIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
    func checkTextureIndex(c: inout Compute, index: Int?) -> Int{
        if index == nil {
            let index = textureIndexCounter
            c.textureIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
}
