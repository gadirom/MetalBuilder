
import SwiftUI
import MetalKit

/// Declares an MTLBufferContainer state
///
/// metalType and metalName - supposed type and name for the buffer in MSL code
@propertyWrapper
public final class MetalBuffer<T>{
    public var wrappedValue: MTLBufferContainer<T>
    
    public var projectedValue: MetalBuffer<T>{
        self
    }
    
    public init(wrappedValue: MTLBufferContainer<T>){
        self.wrappedValue = wrappedValue
    }
    
    public init(count: Int? = nil, metalType: String? = nil, metalName: String? = nil){
        self.wrappedValue = MTLBufferContainer<T>(count: count, metalType: metalType, metalName: metalName)
    }
}

enum MetalBuilderBufferError: Error {
case bufferNotCreated
}

public class BufferContainer{
    
    var buffer: MTLBuffer?
    
    public let count: Int?
    public var elementSize: Int?
    
    public var metalType: String?
    public var metalName: String?
    
    init(count: Int? = nil, metalType: String? = nil, metalName: String? = nil) {
        self.count = count
        
        self.metalType = metalType
        self.metalName = metalName
    }
}

/// Container class for MTLBuffer
///
/// You can access it's content on CPU through 'pointer'
public final class MTLBufferContainer<T>: BufferContainer{

    public var pointer: UnsafeMutablePointer<T>?
    
    func create(device: MTLDevice) throws{
        elementSize = MemoryLayout<T>.stride
        let length = elementSize!*count!
        buffer = device.makeBuffer(length: length)
        if let buffer = buffer{
            pointer = buffer.contents().bindMemory(to: T.self, capacity: length)
        }else{
            throw MetalBuilderBufferError
                .bufferNotCreated
        }
    }
}
