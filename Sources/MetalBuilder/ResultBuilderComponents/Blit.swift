
import MetalKit
import SwiftUI

/// Blit Component
///
/// initializes a blit pass
/// if no destination is set tries to copy to drawable
public struct Blit: MetalBuilderComponent{
    var outTexture: MTLTextureContainer?
    var inTexture: MTLTextureContainer?
    
    var size: Binding<MTLSize>?
    public init(){
    }
}

// chaining dunctions
public extension Blit{
    func source(_ container: MTLTextureContainer)->Blit{
        var b = self
        b.inTexture = container
        return b
    }
    func destination(_ container: MTLTextureContainer)->Blit{
        var b = self
        b.outTexture = container
        return b
    }
    func size(size: Binding<MTLSize>)->Blit{
        var b = self
        b.size = size
        return b
    }
}
