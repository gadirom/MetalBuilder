
import MetalKit
import SwiftUI

public var defaultTexturesSeparatePlacement = false
public var defaultBytesSeparatePlacement = true // for now the bytes are always separate
public var defaultBuffersSeparatePlacement = false

protocol ContainerOfResources{
    var indexCounter: Int{ get set }
}
extension ContainerOfResources{
    mutating func checkIndex(index: Int?) -> Int{
        if index == nil {
            let index = indexCounter
            indexCounter += 1
            return index
        }else{
            return index!
        }
    }
}

struct ContainerOfBuffersBytesAndUniforms: ContainerOfResources{
    var indexCounter: Int = 0
    var buffers: [BufferProtocol] = []
    var bytes: [BytesProtocol] = []
    
    mutating func addBuffer(_ buf: BufferProtocol,
                               offset: MetalBinding<Int>,
                               argument: MetalBufferArgument) -> MetalFunctionArgument{
        var argument = argument
        var buf = buf
        argument.index = checkIndex(index: argument.index)
        buf.index = argument.index!
        self.buffers.append(buf)
        return .buffer(argument)
    }
    mutating func addBytes(_ bytes: BytesProtocol,
                           argument: MetalBytesArgument)->MetalFunctionArgument{
        var argument = argument
        argument.index = checkIndex(index: argument.index)
        self.bytes.append(bytes)
        return .bytes(argument)
    }
}

struct ContainerOfTextures: ContainerOfResources{
    var indexCounter: Int = 0
    var textures: [Texture] = []
    
    mutating func add(_ tex: Texture?,//if drawable the tex is nil
                      argument: MetalTextureArgument) -> MetalFunctionArgument{
        var argument = argument
        argument.index = checkIndex(index: argument.index)
        if let tex{
            self.textures.append(tex)
        }
        return .texture(argument)
    }
}

struct ArgumentsContainer{
    
    var separateShaderArguments: [MetalFunctionArgument] = []
    
    var argumentsBuffer: ArgumentsBuffer
    
    let shaderName: String
    var uniforms: [UniformsContainer] = []
    var buffersAndBytesContainer = ContainerOfBuffersBytesAndUniforms()
    var texturesContainer = ContainerOfTextures()
    init(shaderName: String){
        self.shaderName = shaderName
        argumentsBuffer = ArgumentsBuffer(functionName: shaderName)
    }
}

extension ArgumentsContainer{
    func setup() throws -> String{
        try argumentsBuffer.typeDeclaration
    }
    func getBuffersAndTextures() -> ([BufferProtocol], [MTLTextureContainer]){
        var (bufs, texs) =
        (buffersAndBytesContainer.buffers,
         texturesContainer.textures)
        let (bufsA, texsA) = argumentsBuffer.buffersAndTextures
        bufs.append(contentsOf: bufsA)
        texs.append(contentsOf: texsA)
        return (bufs, texs.map{ $0.container })
    }
}

extension ArgumentsContainer{
    mutating func buffer<T>(_ container: MTLBufferContainer<T>,
                   offset: MetalBinding<Int>,
                   index: Int){
        let buff = Buffer(container: container, offset: offset, index: index)
        self.buffersAndBytesContainer.buffers.append(buff)
    }
    mutating func buffer<T>(_ container: MTLBufferContainer<T>,
                   offset: MetalBinding<Int>,
                   argument: MetalBufferArgument,
                   separate: Bool){
        let buf = Buffer(container: container, offset: offset, index: 0)
        if separate{
            let arg = self.buffersAndBytesContainer.addBuffer(buf,
                                                                   offset: offset,
                                                                   argument: argument)
            self.separateShaderArguments.append(arg)
        }else{
            self.argumentsBuffer.addBuffer(buf, bufArgument: argument)
        }
    }
    mutating func bytes<T>(_ binding: Binding<T>, index: Int){
        let bytes = Bytes(binding: binding, index: index)
        self.buffersAndBytesContainer.bytes.append(bytes)
    }
    mutating func bytes<T>(_ binding: Binding<T>,
                  argument: MetalBytesArgument, separate: Bool){
        let bytes = Bytes(binding: binding, index: 0)
        if separate{
            let arg = self.buffersAndBytesContainer.addBytes(bytes, argument: argument)
            self.separateShaderArguments.append(arg)
        }else{
            //argumentsBuffer.addBytes(bytes, buffArgument: argument)
        }
    }
    mutating func uniforms(_ uniforms: UniformsContainer, name: String?){
        self.uniforms.append(uniforms)
        let argument = MetalBytesArgument(uniformsContainer: uniforms, name: name)
        let bytes = RawBytes(binding: uniforms.pointerBinding,
                             length: uniforms.length,
                             index: argument.index!)
        let arg = self.buffersAndBytesContainer.addBytes(bytes, argument: argument)
        self.separateShaderArguments.append(arg)
    }
    mutating func texture(_ container: MTLTextureContainer, index: Int){
        let tex = Texture(container: container, index: index)
        self.texturesContainer.textures.append(tex)
    }
    mutating func texture(_ container: MTLTextureContainer,
                 argument: MetalTextureArgument,
                 separate: Bool){
        var argument = argument
        argument.textureType = container.descriptor.type
        let tex = Texture(container: container, index: 0)
        if separate{
            let arg = self.texturesContainer.add(tex, argument: argument)
            self.separateShaderArguments.append(arg)
        }else{
            argumentsBuffer.addTexture(tex, texArgument: argument)
        }
    }
    mutating func drawable(argument: MetalTextureArgument)->Int{
        var argument = argument
        argument.textureType = .type2D
        let arg = self.texturesContainer.add(nil, argument: argument)
        self.separateShaderArguments.append(arg)
        return arg.index
    }
}
