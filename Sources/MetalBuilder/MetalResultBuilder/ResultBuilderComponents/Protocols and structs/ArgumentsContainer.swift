
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
        var bytes = bytes
        argument.index = checkIndex(index: argument.index)
        bytes.index = argument.index!
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
        if var tex{
            tex.index = argument.index!
            self.textures.append(tex)
        }
        return .texture(argument)
    }
}

struct ArgumentsContainer{
    
    var separateShaderArguments: [MetalFunctionArgument] = []
    
    let shaderName: String
    var uniforms: [UniformsContainer] = []
    var argumentBuffers: [ArgumentBuffer] = []
    var buffersAndBytesContainer = ContainerOfBuffersBytesAndUniforms()
    var texturesContainer = ContainerOfTextures()
    init(shaderName: String){
        self.shaderName = shaderName
    }
}

extension ArgumentsContainer{
    func setup() throws -> String{
        //try argumentsBuffer.typeDeclaration
        ""
    }
    func getBuffersAndTextures() -> ([BufferProtocol], [MTLTextureContainer]){
        let (bufs, texs) =
        (buffersAndBytesContainer.buffers,
         texturesContainer.textures)
//        let (bufsA, texsA) = argumentsBuffer.buffersAndTextures
//        bufs.append(contentsOf: bufsA)
//        texs.append(contentsOf: texsA)
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
                   argument: MetalBufferArgument){
        let buf = Buffer(container: container, offset: offset, index: 0)
        let arg = self.buffersAndBytesContainer.addBuffer(buf,
                                                           offset: offset,
                                                           argument: argument)
        self.separateShaderArguments.append(arg)
    }
    mutating func bytes<T>(_ binding: Binding<T>, index: Int){
        let bytes = Bytes(binding: binding, index: index)
        self.buffersAndBytesContainer.bytes.append(bytes)
    }
    mutating func bytes<T>(_ binding: Binding<T>,
                  argument: MetalBytesArgument){
        let bytes = Bytes(binding: binding, index: 0)
        let arg = self.buffersAndBytesContainer.addBytes(bytes, argument: argument)
        self.separateShaderArguments.append(arg)
    }
    mutating func uniforms(_ uniforms: UniformsContainer, name: String?){
        self.uniforms.append(uniforms)
        let argument = MetalBytesArgument(uniformsContainer: uniforms, name: name)
        let bytes = RawBytes(binding: uniforms.pointerBinding,
                             length: uniforms.length,
                             index: 0)
        let arg = self.buffersAndBytesContainer.addBytes(bytes, argument: argument)
        self.separateShaderArguments.append(arg)
    }
    mutating func texture(_ container: MTLTextureContainer, index: Int){
        let tex = Texture(container: container, index: index)
        self.texturesContainer.textures.append(tex)
    }
    mutating func texture(_ container: MTLTextureContainer,
                  argument: MetalTextureArgument){
        var argument = argument
        argument.textureType = container.descriptor.type
        let tex = Texture(container: container, index: 0)
        let arg = self.texturesContainer.add(tex, argument: argument)
        self.separateShaderArguments.append(arg)
    }
    mutating func drawable(argument: MetalTextureArgument)->Int{
        var argument = argument
        argument.textureType = .type2D
        let arg = self.texturesContainer.add(nil, argument: argument)
        self.separateShaderArguments.append(arg)
        return arg.index
    }
}
