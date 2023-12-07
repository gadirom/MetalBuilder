import MetalKit
import SwiftUI

//#argumentBuffer
//myBuffer{
//    TextureResource(myTexture, access: .readWrite, name: "texure")
//}
//
//var argBuffer: ArgBuffer{
//    ArgBuffer("argBuffer", desc:
//        ArgumentBufferDescriptor("ArgBuffer")
//            .texture(myTexture, access: .readWrite, name: "texure")
//            .buffer(myBuffer, offset: .constant(0), name: "buffer")
//            .bytes(myBytes, name: "bytes")
//              )
//}
//Compute()
//    .arguments(argBuffer,
//               UseResources()
//        .texture("texture", .read)
//        .buffer("buffer", .write)
//    )
//class argbuffer(){
//    init
//}


// TODO
// performance monitor of change textures
// make everything same for render

struct ArgBufferInfo{
    var argBuffers: [(ArgumentBuffer, Int, MetalBinding<Int>)] = [] // arg buffer and id in that buffer
}

protocol MTLResourceContainer: AnyObject{
    var mtlResource: MTLResource{ get }
    var argBufferInfo: ArgBufferInfo {get set}
    var dataType: MTLDataType { get }
    func updateResource(argBuffer: ArgumentBuffer, id: Int, offset: Int)
}
extension MTLResourceContainer{
    var id: UnsafeMutableRawPointer{
          Unmanaged.passUnretained(self).toOpaque()
    }
    func addToArgumentBuffer<T: ArgumentBuffer>(_ argBuffer: T, id: Int, offset: MetalBinding<Int>){
        argBufferInfo.argBuffers.append((argBuffer, id, offset))
    }
    func updateResourceInArgumentBuffers(){
        _ = argBufferInfo.argBuffers.map { (argBuffer, id, offset) in
            self.updateResource(argBuffer: argBuffer, id: id, offset: offset.wrappedValue)
        }
    }
}

public class ArgumentBuffer{
    
    static var argumentBuffersSingleton: [ArgumentBuffer] = []
    
    let name: String
    let type: String
    var descriptor: ArgumentBufferDescriptor!
    
    var buffer = MTLBufferContainer<CChar>(count: 1, passAs: .singleReference)
    var encoder: MTLArgumentEncoder!
    
    var wasSetUp = false
    
//    static func createBuffers(device: MTLDevice) throws{
//        for argBuf in argumentBuffersSingleton{
//           // argBuf.create(device: <#T##MTLDevice#>, mtlFunction: <#T##MTLFunction#>, index: <#T##Int#>)
//        }
//    }
    
    public static func new(_ name: String, desc: ArgumentBufferDescriptor) -> ArgumentBuffer{
        if let argBuf = argumentBuffersSingleton.first(where: { $0.name == name }){
            return argBuf
        }else{
            return self.init(name, desc: desc)
        }
    }
    required init(_ name: String, desc: ArgumentBufferDescriptor){
        self.name = name
        self.type = desc.type ?? name.uppercased()
        self.descriptor = desc
        Self.argumentBuffersSingleton.append(self)
    }
}

extension ArgumentBuffer{
    var typeDeclaration: String{
        "struct \(type) {};\n"
    }
    func functionArgument(name: String?) -> MetalBufferArgument{
         try! .init(buffer,
                    space: "device",
                    type: type,
                    name: name ?? self.name,
                    index: nil)
    }
    func setup() throws -> ([BufferProtocol], [MTLTextureContainer], FunctionAndArguments?, String) {// - metal declaration
        if wasSetUp{ return ([], [], nil, "") }
        wasSetUp = true
        var buffers: [BufferProtocol] = []
        var texures: [MTLTextureContainer] = []
        for entry in descriptor.arguments.enumerated(){
            if let buf = entry.element.0.resource as? BufferContainer{
                buffers.append(buf.createBufferProtocolConformingBuffer())
            }
            if let tex = entry.element.0.resource as? MTLTextureContainer{
                texures.append(tex)
            }
            entry.element.0.resource
                .addToArgumentBuffer(self, id: entry.offset, offset: entry.element.0.offset)
        }
        let funcAndArgs = FunctionAndArguments(function: .argBuffer(type),
                                               arguments: descriptor.arguments.map{ $0.1 })
        return (buffers, texures, funcAndArgs, typeDeclaration)
    }
    func create(device: MTLDevice,
                mtlFunction: MTLFunction,
                index: Int) throws {
        if buffer.buffer != nil{ return }
        
        encoder = mtlFunction.makeArgumentEncoder(bufferIndex: index)
        buffer.count = encoder.encodedLength
        buffer.metalName = type+"_buffer"
    }
    func setEncoder(){
        encoder.setArgumentBuffer(buffer.buffer, offset: 0)
    }
}
