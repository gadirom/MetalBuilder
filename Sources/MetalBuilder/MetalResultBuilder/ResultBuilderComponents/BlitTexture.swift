
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
    
    var size: Binding<MTLSize>?
    public init(){
    }
}

// chaining dunctions
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
    func size(size: Binding<MTLSize>)->BlitTexture{
        var b = self
        b.size = size
        return b
    }
}
