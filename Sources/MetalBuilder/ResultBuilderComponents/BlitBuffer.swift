
import MetalKit
import SwiftUI

/// BlitBuffer Component
///
/// initializes a blit pass
public struct BlitBuffer: MetalBuilderComponent{
    var inBuffer: BufferContainer?
    var outBuffer: BufferContainer?
    
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
        b.inBuffer = container
        return b
    }
    func destination<T>(_ container: MTLBufferContainer<T>)->BlitBuffer{
        var b = self
        b.outBuffer = container
        return b
    }
    func count(count: Int)->BlitBuffer{
        var b = self
        b.count = count
        return b
    }
}
