import MetalKit
import SwiftUI

// Blit pass
class BlitPass: MetalPass{
    let component: Blit
    
    init(_ component: Blit){
        self.component = component
    }
    func setup(device: MTLDevice, library: MTLLibrary){
    }
    func encode(_ commandBuffer: MTLCommandBuffer,_ drawable: CAMetalDrawable?) {
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
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
            blitEncoder?.copy(from: inTexture,
                              sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: size,
                              
                              to: outTexture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
            blitEncoder?.endEncoding()
        }
    }
}
