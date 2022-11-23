import Metal
import SwiftUI

/// The render pass that clears a texture.
///
/// Pass the texture to clear and the color with modifiers.
/// if no texture is passed the drawable of the view will be cleared.
/// Keep in mind that usually several drawables are created for the view.
/// You should clear them all to avoid flickering or other artifacts.
/// To clear all the drawables the ClearRender component should be active for several frames.
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
        guard let cgC = UIColor(color).cgColor.components
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
