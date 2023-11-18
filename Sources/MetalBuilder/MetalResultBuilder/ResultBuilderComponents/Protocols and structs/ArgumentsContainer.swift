
import MetalKit
import SwiftUI

struct ArgumentsContainer{
    
    var arguments: [MetalFunctionArgument] = []
    
    var bufferIndexCounter = 0
    var textureIndexCounter = 0
    var argumentsCounter = 0
    
    var uniforms: [UniformsContainer] = []
    
    var argumentBuffer = ArgumentBuffer()
    
    let shaderName: String
    var buffers: [BufferProtocol] = []
    var bytes: [BytesProtocol] = []
    var textures: [Texture] = []
}

extension ArgumentsContainer{
    func buffer<T>(_ container: MTLBufferContainer<T>,
                   offset: Int,
                   index: Int)->Self{
        var c = self
        let buf = Buffer(separate: true, container: container, offset: offset, index: index)
        c.buffers.append(buf)
        return c
    }
    func buffer<T>(_ container: MTLBufferContainer<T>,
                   offset: Int, argument: MetalBufferArgument,
                   separate: Bool)->Self{
        var c = self
        var argument = argument
        if separate{
            argument.index = checkBufferIndex(c: &c, index: argument.index)
        }else{
            argument.index = argumentsCounter
            c.argumentsCounter += 1
        }
        c.arguments.append(.buffer(argument))
        let buf = Buffer(separate: separate, container: container, offset: offset, index: argument.index!)
        c.buffers.append(buf)
        return c
    }
    func buffer<T>(_ container: MTLBufferContainer<T>,
                   offset: Int,
                   space: String,
                   type: String,
                   name: String,
                   separate: Bool) -> Self{
        
        let argument = try! MetalBufferArgument(container, space: space, type: type, name: name)
        return self.buffer(container, offset: offset, argument: argument, separate: separate)
    }
    func bytes<T>(_ binding: Binding<T>, index: Int)->Self{
        var c = self
        let bytes = Bytes(separate: true, binding: binding, index: index)
        c.bytes.append(bytes)
        return c
    }
    func bytes<T>(_ binding: Binding<T>,
                  argument: MetalBytesArgument, separate: Bool)->Self{
        var c = self
        var argument = argument
        if separate{
            argument.index = checkBufferIndex(c: &c, index: argument.index)
        }else{
            argument.index = argumentsCounter
            c.argumentsCounter += 1
        }
        c.arguments.append(.bytes(argument))
        let bytes = Bytes(separate: separate, binding: binding, index: argument.index!)
        c.bytes.append(bytes)
        return c
    }
    func bytes<T>(_ binding: MetalBinding<T>,
                  argument: MetalBytesArgument,
                  separate: Bool)->Self{
        return self.bytes(binding.binding, argument: argument, separate: separate)
    }
    func bytes<T>(_ binding: MetalBinding<T>,
                  space: String,
                  type: String,
                  name: String,
                  index: Int,
                  separate: Bool)->Self{
        let argument = MetalBytesArgument(binding: binding, space: space, type: type, name: name, index: index)
        return self.bytes(binding, argument: argument, separate: separate)
    }
    func bytes<T>(_ binding: Binding<T>,
                  space: String,
                  type: String,
                  name: String,
                  index: Int,
                  separate: Bool)->Self{
        let metalBinding = MetalBinding(binding: binding, metalType: type, metalName: name)
        let argument = MetalBytesArgument(binding: metalBinding, space: space, type: type, name: name, index: index)
        return self.bytes(binding, argument: argument, separate: separate)
    }
    func uniforms(_ uniforms: UniformsContainer, name: String) -> Self{
        var c = self
        c.uniforms.append(uniforms)
        var argument = MetalBytesArgument(uniformsContainer: uniforms, name: name)
        argument.index = checkBufferIndex(c: &c, index: nil)
        c.arguments.append(.bytes(argument))
        let bytes = RawBytes(separate: true, binding: uniforms.pointerBinding,
                             length: uniforms.length,
                             index: argument.index!)
        c.bytes.append(bytes)
        return c
    }
    func texture(_ container: MTLTextureContainer, index: Int)->Self{
        var c = self
        let tex = Texture(separate: true, container: container, index: index)
        c.textures.append(tex)
        return c
    }
    func texture(_ container: MTLTextureContainer,
                 argument: MetalTextureArgument,
                 separate: Bool)->Self{
        var c = self
        var argument = argument
        if separate{
            argument.index = checkTextureIndex(c: &c, index: argument.index)
        }else{
            argument.index = argumentsCounter
            c.argumentsCounter += 1
        }
        argument.textureType = container.descriptor.type
        c.arguments.append(.texture(argument))
        let tex = Texture(separate: separate, container: container, index: argument.index!)
        c.textures.append(tex)
        return c
    }
}

extension ArgumentsContainer{
    func checkBufferIndex(c: inout ArgumentsContainer, index: Int?) -> Int{
        if index == nil {
            let index = bufferIndexCounter
            c.bufferIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
    func checkTextureIndex(c: inout ArgumentsContainer, index: Int?) -> Int{
        if index == nil {
            let index = textureIndexCounter
            c.textureIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
}

//work with argument buffer
extension ArgumentsContainer{
    var argumentBufferTypeDecl: String{
        get throws{
            try argumentBufferTypeDeclaration(shaderFunctionName: shaderName,
                                              arguments: arguments)
        }
    }
    func createArgumentBuffer(){
        argumentBuffer.typeName = shaderName
    }
}
