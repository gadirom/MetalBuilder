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

struct ArgBufferInfo{
    var argBuffers: [(ArgumentBuffer, Int, MetalBinding<Int>)] = [] // arg buffer and id in that buffer
    
    func withArrayIndex(_ id: Int) -> Self{
        let a = self.argBuffers.map{
            ($0.0, $0.1+id, $0.2)
        }
        return Self(argBuffers: a)
    }
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
    func functionArgument(name: String?, space: String) -> MetalBufferArgument{
         try! .init(buffer,
                    space: space,
                    type: type,
                    name: name ?? self.name,
                    index: nil)
    }
    func setup() throws -> ArgumentsData {// - metal declaration
        var argData = ArgumentsData()
        if wasSetUp{ return argData }
        wasSetUp = true
        
        for entry in descriptor.arguments.enumerated(){
            if let buf = entry.element.0.resource as? BufferContainer{
                argData.buffers.append(buf.createBufferProtocolConformingBuffer())
            }
            if let tex = entry.element.0.resource as? MTLTextureContainer{
                argData.textures.append(tex)
            }
            entry.element.0.resource?
                .addToArgumentBuffer(self, id: entry.element.1.index,
                                     offset: entry.element.0.offset)
            entry.element.0.array?
                .argBufferInfo.argBuffers.append(
                    (self, id: entry.element.1.index,
                     offset: entry.element.0.offset)
                )
        }
        argData.funcAndArgs = [FunctionAndArguments(function: .argBuffer(type),
                                                    arguments: descriptor.arguments.map{ $0.1 })]
        argData.argBufDecls = typeDeclaration
        return argData
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
