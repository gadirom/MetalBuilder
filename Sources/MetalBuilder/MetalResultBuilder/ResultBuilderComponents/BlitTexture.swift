
import MetalKit
import SwiftUI

/// The component for copying textures.
///
/// Use this component to copy memory between textures on GPU.
/// Configure source, destination, sliceCount and size with modifiers.
/// If no destination is set tries to copy to drawable.
public struct BlitTexture: MetalBuilderComponent{
    
    var inTexture: MTLTextureContainer?
    var outTexture: MTLTextureContainer?
    
    var sourceSlice: MetalBinding<Int>?
    var destinationSlice: MetalBinding<Int>?
    
    var sliceCount: MetalBinding<Int> = .constant(1)
    var mipmapsCount: MetalBinding<Int> = .constant(1)
    
    let label: String
    
    var size: MetalBinding<MTLSize>?
    public init(_ label: String=""){
        self.label = label
    }
}

// modifiers for BlitTexture.
public extension BlitTexture{
    func source(_ container: MTLTextureContainer, slice: MetalBinding<Int>=MetalBinding<Int>.constant(0))->BlitTexture{
        var b = self
        b.sourceSlice = slice
        b.inTexture = container
        return b
    }
    func destination(_ container: MTLTextureContainer?,
                     slice: MetalBinding<Int> = .constant(0))->BlitTexture{
        var b = self
        b.destinationSlice = slice
        b.outTexture = container
        return b
    }
    func sliceCount(_ binding: MetalBinding<Int>)->BlitTexture{
        var b = self
        b.sliceCount = binding
        return b
    }
    func sliceCount(_ n: Int)->BlitTexture{
        var b = self
        b.sliceCount = MetalBinding<Int>.constant(n)
        return b
    }
    func mipmapsCount(_ binding: MetalBinding<Int>)->BlitTexture{
        var b = self
        b.mipmapsCount = binding
        return b
    }
    func mipmapsCount(_ n: Int)->BlitTexture{
        var b = self
        b.mipmapsCount = MetalBinding<Int>.constant(n)
        return b
    }
    /*func size(size: Binding<MTLSize>)->BlitTexture{
        var b = self
        b.size = size
        return b
    }*/
}
