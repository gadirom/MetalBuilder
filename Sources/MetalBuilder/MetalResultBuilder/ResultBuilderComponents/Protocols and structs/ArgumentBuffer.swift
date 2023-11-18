import MetalKit
import OrderedCollections



//each resource has:
//argument buffers info:
//array of references to argument buffer

func argumentBufferTypeDeclaration(shaderFunctionName: String,
                                   arguments: [MetalFunctionArgument]) throws -> String{
    "struct ArgumentsFor_"+shaderFunctionName+"{"
    + (try arguments.enumerated().map {
        try $1.string(forArgumentsBuffer: true,
                      argumentIndex: $0)
        
    }.joined())
    + "};"
}


struct ArgBufferInfo{
    var argBuffers: [(ArgumentBuffer, Int)] = [] // arg buffer and id in that buffer
}

protocol MBResource: AnyObject{
    var device: MTLDevice? {get}
    var argBufferInfo: ArgBufferInfo {get set}
    var dataType: MTLDataType {get}
}
extension MBResource{
    func addToArgumentBuffer<T: ArgumentBuffer>(_ argBuffer: T, id: Int){
        argBufferInfo.argBuffers.append((argBuffer, id))
    }
    func updateResourceInArgumentBuffers(){
        _ = argBufferInfo.argBuffers.map { (argBuffer, id) in
            argBuffer.updateResource(self, id: id)
        }
    }
}

//extension MetalState

extension MTLBufferContainer: MBResource{
}
extension MTLTextureContainer: MBResource{
}

//global argument buffers array with elements:
//argument encoder
//argument buffer
class ArgumentBuffer{
    var typeName: String = ""
    var buffer = MTLBufferContainer<Any>()
    var encoder: MTLArgumentEncoder!
}
extension ArgumentBuffer{
    func create(device: MTLDevice,
                mtlFunction: MTLFunction,
                arguments: [MetalFunctionArgument]){
        let encoder = mtlFunction.makeArgumentEncoder(bufferIndex: 0)
        buffer.buffer = device.makeBuffer(length: encoder.encodedLength)!
        buffer.buffer!.label = typeName+"_buffer"
        encoder.setArgumentBuffer(buffer.buffer, offset: 0)
    }
    func updateResource(_ resource: MBResource, id: Int){
        switch resource.dataType {
        case .pointer:
            if let buffer = (resource as! BufferContainer).buffer{
                encoder.setBuffer(buffer, offset: 0, // offset -???
                                  index: id)
            }
        case .texture:
            if let texture = (resource as! MTLTextureContainer).texture{
                encoder.setTexture(texture, index: id)
            }
        default:
            return
        }
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

