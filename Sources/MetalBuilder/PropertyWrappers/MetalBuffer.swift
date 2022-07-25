
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

public final class MTLBufferContainer<T>{
    public var buffer: MTLBuffer?
    public var pointer: UnsafeMutablePointer<T>?
    public let count: Int
    
    init(count: Int) {
        self.count = count
    }
    func create(device: MTLDevice) throws{
        let length = MemoryLayout<T>.stride*count
        buffer = device.makeBuffer(length: length)
        if let buffer = buffer{
            pointer = buffer.contents().bindMemory(to: T.self, capacity: length)
        }else{
            throw MetalBuilderBufferError
                .bufferNotCreated
        }
    }
}
