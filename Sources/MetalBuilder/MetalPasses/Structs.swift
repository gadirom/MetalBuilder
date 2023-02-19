import MetalKit
import SwiftUI

public protocol BufferProtocol{
    var mtlBuffer: MTLBuffer? { get }
    var offset: Int { get }
    var index: Int { get set }
    
    var elementSize: Int { get }
    var count: Int { get }
    
    var elementType: Any.Type { get }
    var swiftTypeToMetal: SwiftTypeToMetal? { get }
    func create(device: MTLDevice) throws
}

struct Buffer<T>: BufferProtocol{
    
    var elementType: Any.Type{
        T.self
    }
    
    func create(device: MTLDevice) throws {
        try container.create(device: device)
    }
    
    let container: MTLBufferContainer<T>
    let offset: Int
    var index: Int
    
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
    var index: Int
}

protocol BytesProtocol{
    var index: Int {get set}
    func encode(encoder: (UnsafeRawPointer, Int, Int)->())
}

struct RawBytes: BytesProtocol{
    let binding: Binding<UnsafeRawPointer?>
    let length: Int
    var index: Int

    func encode(encoder: (UnsafeRawPointer, Int, Int)->()){
        let value = binding.wrappedValue!
        encoder(value, length, index)
    }
}

struct Bytes<T>: BytesProtocol{
    let binding: Binding<T>
    var index: Int
    
    func encode(encoder: (UnsafeRawPointer, Int, Int)->()){
        let value = binding.wrappedValue
        withUnsafeBytes(of: value){ pointer in
            encoder(pointer.baseAddress!,
                    MemoryLayout<T>.stride,
                    index)
        }
    }
}

