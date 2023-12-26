import MetalKit
import SwiftUI

// BlitTexture pass
class BlitArrayOfTexturesPass: MetalPass{
    var libraryContainer: LibraryContainer?
    
    let component: BlitArrayOfTextures
    
    init(_ component: BlitArrayOfTextures){
        var component = component
        if component.outRange == nil{
            component.outRange = component.inRange
        }
        self.component = component
    }
    func setup(renderInfo: GlobalRenderInfo){
    }
    func encode(passInfo: MetalPassInfo) throws{
            
        let commandBuffer = passInfo.getCommandBuffer()
        
        let sourceSlice = component.sourceSlice.wrappedValue
        let destinationSlice = component.destinationSlice.wrappedValue
        
        let blitTextureEncoder = commandBuffer.makeBlitCommandEncoder()
        
        if component.inRange.wrappedValue.count != component.outRange!.wrappedValue.count{
            return
        }
        
        let shift = component.outRange!.wrappedValue.lowerBound - component.inRange.wrappedValue.lowerBound
        
        for inId in component.inRange.wrappedValue{
            
            let outId = inId + shift
            
            guard let inTexture = component.inArray?[inId]?.texture
            else { return }
            
            guard let outTexture = component.outContainer?.texture ?? component.outArray?[outId]?.texture
            else { return }
            
            print("blit textureIn size: \(inTexture.width)x\(inTexture.height)")
            print("blit textureOut size: \(outTexture.width)x\(outTexture.height)")
            
            
            blitTextureEncoder?.copy(from: inTexture,
                                     sourceSlice: sourceSlice,
                                     sourceLevel: 0,
                                     
                                     to: outTexture,
                                     destinationSlice: destinationSlice,
                                     destinationLevel: 0,
                                     sliceCount: component.sliceCount.wrappedValue,
                                     levelCount: 1)
        }
        blitTextureEncoder?.endEncoding()
    }
}
