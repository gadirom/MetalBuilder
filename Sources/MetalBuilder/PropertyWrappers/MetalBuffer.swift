
import SwiftUI
import MetalKit

@propertyWrapper
public final class MetalBuffer<T>{
    public var wrappedValue: MTLBufferContainer<T>
    
    public init(wrappedValue: MTLBufferContainer<T>){
        self.wrappedValue = wrappedValue
    }
    
    public init(count: Int){
        self.wrappedValue = MTLBufferContainer<T>(count: count)
    }
}

enum MetalBuilderBufferError: Error {
case bufferNotCreated
}

public class BufferContainer{
    var buffer: MTLBuffer?
    public let count: Int
    public var elementSize: Int?
    
    init(count: Int) {
        self.count = count
    }
}

public final class MTLBufferContainer<T>: BufferContainer{
    //public var buffer: MTLBuffer?
    public var pointer: UnsafeMutablePointer<T>?
    
    func create(device: MTLDevice) throws{
        elementSize = MemoryLayout<T>.stride
        let length = elementSize!*count
        buffer = device.makeBuffer(length: length)
        if let buffer = buffer{
            pointer = buffer.contents().bindMemory(to: T.self, capacity: length)
        }else{
            throw MetalBuilderBufferError
                .bufferNotCreated
        }
    }
}
