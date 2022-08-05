
import MetalKit
import SwiftUI

/// BlitTexture Component
///
/// initializes a blit pass
/// if no destination is set tries to copy to drawable
public struct BlitTexture: MetalBuilderComponent{
    
    var inTexture: MTLTextureContainer?
    var outTexture: MTLTextureContainer?
    
    var size: Binding<MTLSize>?
    public init(){
    }
}

// chaining dunctions
public extension BlitTexture{
    func source(_ container: MTLTextureContainer)->BlitTexture{
        var b = self
        b.inTexture = container
        return b
    }
    func destination(_ container: MTLTextureContainer)->BlitTexture{
        var b = self
        b.outTexture = container
        return b
    }
    func size(size: Binding<MTLSize>)->BlitTexture{
        var b = self
        b.size = size
        return b
    }
}
