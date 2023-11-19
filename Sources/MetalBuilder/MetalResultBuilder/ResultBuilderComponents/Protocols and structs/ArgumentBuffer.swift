import MetalKit
import OrderedCollections

//each resource has:
//argument buffers info:
//array of references to argument buffer

struct ArgBufferInfo{
    var argBuffers: [(ArgumentBuffer, Int)] = [] // arg buffer and id in that buffer
}

protocol MBResource: AnyObject{
    var device: MTLDevice? {get}
    var argBufferInfo: ArgBufferInfo {get set}
    var dataType: MTLDataType {get}
    //func updateResource(encoder: MTLArgumentEncoder, offset: Int, id: Int)
}
extension MBResource{
    func addToArgumentBuffer<T: ArgumentBuffer>(_ argBuffer: T, id: Int){
        argBufferInfo.argBuffers.append((argBuffer, id))
    }
    func updateResourceInArgumentBuffers(){
        _ = argBufferInfo.argBuffers.map { (argBuffer, id) in
            argBuffer.updateResource(id: id)
        }
    }
}

//extension MetalState

extension MTLBufferContainer: MBResource{
}
extension MTLTextureContainer: MBResource{
}

protocol TextureOrBuffer{
    func updateResource(encoder: MTLArgumentEncoder, id: Int)
}

extension BufferProtocol{
    func updateResource(encoder: MTLArgumentEncoder, id: Int){
        encoder.setBuffer(self.mtlBuffer!, offset: offset.wrappedValue, index: id)
    }
}
extension Texture{
    func updateResource(encoder: MTLArgumentEncoder, id: Int){
        encoder.setTexture(self.container.texture!, index: id)
    }
}

class ArgumentBuffer{
    var typeName: String
    var arguments: [MetalFunctionArgument] = []
    var argumentsCounter = 0
    
    var resources: [TextureOrBuffer] = []
    
    var buffer = MTLBufferContainer<Any>()
    var encoder: MTLArgumentEncoder!
    
    init(functionName: String){
        typeName = functionName.uppercased()+"Arguments"
    }
}
extension ArgumentBuffer{
    func addBuffer<T>(_ buf: Buffer<T>, bufArgument: MetalBufferArgument){
        var buf = buf
        //buf.index = argumentsCounter
        arguments.append(.buffer(bufArgument))
        buf.container.addToArgumentBuffer(self, id: argumentsCounter)
        resources.append(buf)
        //argumentsCounter += 1
    }
//    func addBytes<T>(_ bytes: Bytes<T>, bytesArgument: MetalBytesArgument){
//        var bytes = bytes
//        bytes.index = argumentsCounter
//        arguments.append(.bytes(bytesArgument))
//        //bytes.addToArgumentBuffer(self, id: argumentsCounter)
//        argumentsCounter += 1
//    }
    func addTexture(_ tex: Texture, texArgument: MetalTextureArgument){
        var tex = tex
        //tex.index = argumentsCounter
        arguments.append(.texture(texArgument))
        tex.container.addToArgumentBuffer(self, id: argumentsCounter)
        resources.append(tex)
        //argumentsCounter += 1
    }
}
extension ArgumentBuffer{
    var typeDeclaration: String{
        get throws{
            "struct" + typeName + "{"
            + (try arguments.enumerated().map {
                try $1.string(forArgumentsBuffer: true,
                              argumentIndex: $0)
                
            }.joined())
            + "};"
        }
    }
    var buffersAndTextures: ([BufferProtocol], [Texture]){
        var (bufs, texs) = ([BufferProtocol](), [Texture]())
        _ = resources.map{
            if let buf = $0 as? any BufferProtocol{
                bufs.append(buf)
            }
            if let tex = $0 as? Texture{
                texs.append(tex)
            }
        }
        return (bufs, texs)
    }
    func functionArgument(index: Int) throws -> MetalFunctionArgument{
        let bufferArgument: MetalBufferArgument = try .init(buffer,
                                                        space: "",
                                                        type: typeName,
                                                        name: "arguments",
                                                        index: index)
        return .buffer(bufferArgument)
    }
    func create(device: MTLDevice,
                mtlFunction: MTLFunction,
                index: Int){
        let encoder = mtlFunction.makeArgumentEncoder(bufferIndex: index)
        buffer.buffer = device.makeBuffer(length: encoder.encodedLength)!
        buffer.buffer!.label = typeName+"_buffer"
        encoder.setArgumentBuffer(buffer.buffer, offset: 0)
    }
    func updateResource(id: Int){
        
    }
}

// upon consuming component:
// create arguments struct

// add it to global library source
// create function argument with binded buffer
// add function to library source

// upon setup of component pass:
// create argument encoder
// add it to argumentBuffers array to each resource

// didChange for each resource:
// encode resource to all argument buffers from array

