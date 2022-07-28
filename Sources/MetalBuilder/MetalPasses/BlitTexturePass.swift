import MetalKit
import SwiftUI

// BlitTexture pass
class BlitTexturePass: MetalPass{
    let component: BlitTexture
    
    init(_ component: BlitTexture){
        self.component = component
    }
    func setup(device: MTLDevice, library: MTLLibrary){
    }
    func encode(_ commandBuffer: MTLCommandBuffer,_ drawable: CAMetalDrawable?) {
        if let inTexture = component.inTexture?.texture{
            var size: MTLSize
            if let s = component.size?.wrappedValue{
                size = s
            }else{
                size = MTLSize(width: inTexture.width, height: inTexture.height, depth: 1)
            }
            var outTexture: MTLTexture
            if let t = component.outTexture?.texture{
                outTexture = t
            }else{
                guard let t = drawable?.texture
                else{
                    print("blit: no out was set and no drawable!")
                    return
                }
                outTexture = t
            }
            let blitTextureEncoder = commandBuffer.makeBlitCommandEncoder()
            blitTextureEncoder?.copy(from: inTexture,
                              sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: size,
                              
                              to: outTexture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
            blitTextureEncoder?.endEncoding()
        }
    }
}