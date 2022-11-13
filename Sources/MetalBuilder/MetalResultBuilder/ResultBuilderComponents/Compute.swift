
import MetalKit
import SwiftUI

enum GridFit{
    case fitTexture(MTLTextureContainer),
         size(Binding<MTLSize>),
         size1D(MetalBinding<Int>),
         drawable,
         buffer(Int)
}
/// Compute Component
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
    /// Modifier that passes a buffer for a compute kernel
    /// - Parameters:
    ///   - container: MTLBufferContainer
    ///   - offset: offset
    ///   - index: buffer index in kernel arguments
    ///
    ///   This method adds MTLBuffer to a compute function and doesn't change Metal library code
    ///   Use it if you want to declare kernel's argument manually

    func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int = 0, index: Int)->Compute{
        var c = self
        let buf = Buffer(container: container, offset: offset, index: index)
        c.buffers.append(buf)
        return c
    }
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
    func bytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil, name: String?=nil, index: Int?=nil)->Compute{
        let argument = MetalBytesArgument(binding: binding, space: space, type: type, name: name, index: index)
        return bytes(binding, argument: argument)
    }
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
    /// Modifier that passes a texture for a compute kernel
    /// - Parameters:
    ///   - container: MTLTextureContainer
    ///   - index: texture index in kernel arguments
    ///
    ///   This method adds MTLTexture to a compute function and doesn't change Metal library code
    ///   Use it if you want to declare kernel's argument manually
    func texture(_ container: MTLTextureContainer, index: Int)->Compute{
        var c = self
        let tex = Texture(container: container, index: index)
        c.textures.append(tex)
        return c
    }
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
    /// Modifier that passes a drawable texture for a compute kernel
    /// - Parameters:
    ///   - index: texture index in kernel arguments
    ///
    ///   This method adds drawable texture to a compute function and doesn't change Metal library code
    ///   Use it if you want to declare kernel's argument manually
    func drawableTexture(index: Int)->Compute{
        var c = self
        c.drawableTextureIndex = index
        c.gridFit = .drawable
        return c
    }
    /// Modifier that passes a drawable texture for a compute kernel
    /// - Parameters:
    ///   - index: texture index in kernel arguments
    ///   - argument: MetalTextureArgument, describing argument declaration that should be added to the kernel
    ///
    ///   This method adds drawable texture to a compute function and parse Metal library code automatically adding an argument declaration to kernel function
    ///   Use this modifier if you do not want to declare kernel's argument manually
    ///
    func drawableTexture(argument: MetalTextureArgument)->Compute{
        var c = self
        var argument = argument
        argument.index = checkTextureIndex(c: &c, index: argument.index)
        argument.textureType = .type2D
        c.kernelArguments.append(.texture(argument))
        c.drawableTextureIndex = argument.index
        c.gridFit = .drawable
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
