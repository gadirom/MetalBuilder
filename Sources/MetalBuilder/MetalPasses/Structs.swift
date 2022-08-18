import MetalKit
import SwiftUI

public protocol BufferProtocol{
    var mtlBuffer: MTLBuffer? { get }
    var offset: Int { get }
    var index: Int { get }
    
    var elementSize: Int { get }
    var count: Int { get }
    
    var swiftTypeToMetal: SwiftTypeToMetal? { get }
    func create(device: MTLDevice) throws
}

struct Buffer<T>: BufferProtocol{
    
    func create(device: MTLDevice) throws {
        try container.create(device: device)
    }
    
    let container: MTLBufferContainer<T>
    let offset: Int
    let index: Int
    
    var mtlBuffer: MTLBuffer?{
        container.buffer
    }
    var count: Int{
        container.count!
    }
    var elementSize: Int{
        container.elementSize!
    }
    var swiftTypeToMetal: SwiftTypeToMetal?{
        if T.self is MetalStruct.Type{
            return SwiftTypeToMetal(swiftType: T.self,
                                    metalType: container.metalType)
        }else{
            return nil
        }
    }
}
struct Texture{
    let container: MTLTextureContainer
    let index: Int
}

protocol BytesProtocol{
    func encode(encoder: (UnsafeRawPointer, Int, Int)->())
}

struct RawBytes: BytesProtocol{
    let binding: Binding<UnsafeRawPointer?>
    let length: Int
    let index:Int
    
    func encode(encoder: (UnsafeRawPointer, Int, Int)->()){
        encoder(binding.wrappedValue!, length, index)
        }
}

struct Bytes<T>: BytesProtocol{
    let binding: Binding<T>
    let index: Int
    
    func encode(encoder: (UnsafeRawPointer, Int, Int)->()){
        withUnsafeBytes(of: binding.wrappedValue){ pointer in
            encoder(pointer.baseAddress!,
                    MemoryLayout<T>.stride,
                    index)
        }
    }
}

