
import MetalKit
import SwiftUI

enum GridFit{
    case fitTexture(MTLTextureContainer),
         size(Binding<MTLSize>),
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
    var TextureIndexCounter = 0
    
    public init(_ kernel: String){
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
    func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int = 0, index: Int)->Compute{
        var c = self
        let buf = Buffer(container: container, offset: offset, index: index)
        c.buffers.append(buf)
        return c
    }
    func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int = 0, argument: MetalBufferArgument)->Compute{
        var c = self
        c.kernelArguments.append(.buffer(argument))
        let buf = Buffer(container: container, offset: offset, index: argument.index)
        c.buffers.append(buf)
        return c
    }
    func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int = 0,
                   space: String, type: String?=nil, name: String?=nil) -> Compute{
        
        let argument = try! MetalBufferArgument(container, space: space, type: type, name: name, index: bufferIndexCounter)

        var c = self.buffer(container, offset: offset, argument: argument)
        c.bufferIndexCounter += 1
        return c
    }
    func bytes<T>(_ binding: Binding<T>, index: Int)->Compute{
        var c = self
        let bytes = Bytes(binding: binding, index: index)
        c.bytes.append(bytes)
        return c
    }
    func bytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument)->Compute{
        var c = self
        c.kernelArguments.append(.bytes(argument))
        let bytes = Bytes(binding: binding, index: argument.index)
        c.bytes.append(bytes)
        return c
    }
    func bytes<T>(_ binding: MetalBinding<T>, argument: MetalBytesArgument)->Compute{
        var c = self
        c.kernelArguments.append(.bytes(argument))
        let bytes = Bytes(binding: binding.binding, index: argument.index)
        c.bytes.append(bytes)
        return c
    }
    func texture(_ container: MTLTextureContainer, index: Int)->Compute{
        var c = self
        let tex = Texture(container: container, index: index)
        c.textures.append(tex)
        return c
    }
    func texture(_ container: MTLTextureContainer, argument: MetalTextureArgument)->Compute{
        var c = self
        c.kernelArguments.append(.texture(argument))
        let tex = Texture(container: container, index: argument.index)
        c.textures.append(tex)
        return c
    }
    func drawableTexture(index: Int)->Compute{
        var c = self
        c.drawableTextureIndex = index
        return c
    }
    func drawableTexture(argument: MetalTextureArgument)->Compute{
        var c = self
        c.kernelArguments.append(.texture(argument))
        c.drawableTextureIndex = argument.index
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
}
