
import MetalKit
import SwiftUI

/// BlitTexture Component
///
/// initializes a blit pass
/// if no destination is set tries to copy to drawable
public struct BlitTexture: MetalBuilderComponent{
    
    var inTexture: MTLTextureContainer?
    var outTexture: MTLTextureContainer?
    
    var sourceSlice: Binding<Int>?
    var destinationSlice: Binding<Int>?
    
    var sliceCount: Binding<Int> = Binding<Int>.constant(1)
    
    var size: Binding<MTLSize>?
    public init(){
    }
}

// chaining functions
public extension BlitTexture{
    func source(_ container: MTLTextureContainer, slice: Binding<Int>=Binding<Int>.constant(0))->BlitTexture{
        var b = self
        b.sourceSlice = slice
        b.inTexture = container
        return b
    }
    func destination(_ container: MTLTextureContainer, slice: Binding<Int>=Binding<Int>.constant(0))->BlitTexture{
        var b = self
        b.destinationSlice = slice
        b.outTexture = container
        return b
    }
    func sliceCount(_ binding: Binding<Int>)->BlitTexture{
        var b = self
        b.sliceCount = binding
        return b
    }
    func sliceCount(_ n: Int)->BlitTexture{
        var b = self
        b.sliceCount = Binding<Int>.constant(n)
        return b
    }
    /*func size(size: Binding<MTLSize>)->BlitTexture{
        var b = self
        b.size = size
        return b
    }*/
}
