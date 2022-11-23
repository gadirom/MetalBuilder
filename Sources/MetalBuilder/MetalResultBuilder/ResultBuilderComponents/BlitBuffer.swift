
import MetalKit
import SwiftUI

/// The component for copying buffers.
///
/// Use this component to copy memory between buffers on GPU.
/// Configure source, destination, count with modifiers.
public struct BlitBuffer: MetalBuilderComponent{
    
    var inBuffer: BufferProtocol?
    var outBuffer: BufferProtocol?
    
    var sourceOffset: Int = 0
    var destinationOffset: Int = 0
    var count: Int?
    
    public init(){
    }
}

// chaining dunctions
public extension BlitBuffer{
    func source<T>(_ container: MTLBufferContainer<T>)->BlitBuffer{
        var b = self
        let buffer = Buffer(container: container, offset: 0, index: 0)
        b.inBuffer = buffer
        return b
    }
    func destination<T>(_ container: MTLBufferContainer<T>)->BlitBuffer{
        var b = self
        let buffer = Buffer(container: container, offset: 0, index: 0)
        b.outBuffer = buffer
        return b
    }
    func count(count: Int)->BlitBuffer{
        var b = self
        b.count = count
        return b
    }
}
