import MetalKit
import SwiftUI

// BlitTexture pass
class BlitTexturePass: MetalPass{
    let restartEncode = false
    var libraryContainer: LibraryContainer?
    
    let component: BlitTexture
    
    init(_ component: BlitTexture){
        self.component = component
    }
    func setup(device: MTLDevice){
    }
    func encode(_ commandBuffer: MTLCommandBuffer,_ drawable: CAMetalDrawable?) {
        if let inTexture = component.inTexture?.texture{
            
            let sourceSlice = component.sourceSlice?.wrappedValue
            var destinationSlice = component.destinationSlice?.wrappedValue
            
            /*var size: MTLSize
            if let s = component.size?.wrappedValue{
                size = s
            }else{
                size = MTLSize(width: inTexture.width, height: inTexture.height, depth: 1)
            }*/
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
                destinationSlice = 0
            }
            let blitTextureEncoder = commandBuffer.makeBlitCommandEncoder()
            blitTextureEncoder?.copy(from: inTexture,
                                     sourceSlice: sourceSlice!,
                                     sourceLevel: 0,
                              
                                     to: outTexture,
                                     destinationSlice: destinationSlice!,
                                     destinationLevel: 0,
                                     sliceCount: component.sliceCount.wrappedValue,
                                     levelCount: 1)
            blitTextureEncoder?.endEncoding()
        }
    }
}
