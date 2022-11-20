import Metal
import SwiftUI

/// The render pass that clears the drawable texture.
public struct ClearRender: MetalBuilderComponent{
    
    var texture: MTLTextureContainer?
    var clearColor: MTLClearColor?
    
    public init(){
    }
}

public extension ClearRender{
    func texture(_ container: MTLTextureContainer) -> ClearRender{
        var c = self
        c.texture = container
        return c
    }
    func color(_ mtlClearColor: MTLClearColor) -> ClearRender{
        var c = self
        c.clearColor = mtlClearColor
        return c
    }
    func color(_ color: Color) -> ClearRender{
        guard let cgC = color.cgColor?.components
        else{
            print("Could not get color components for color: ", color)
            return self
        }
        var c = self
        let mtlClearColor = MTLClearColor(red: cgC[0], green: cgC[1], blue: cgC[2], alpha: cgC[3])
        c.clearColor = mtlClearColor
        return c
    }
}
