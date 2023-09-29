import MetalKit
import SwiftUI
import MetalPerformanceShaders

// ScaleTexture pass
class ScaleTexturePass: MetalPass{
    
    var libraryContainer: LibraryContainer?
    
    let component: ScaleTexture
    
    unowned var device: MTLDevice!
    
    init(_ component: ScaleTexture){
        self.component = component
    }
    func setup(renderInfo: GlobalRenderInfo){
        self.device = renderInfo.device
    }
    func encode(passInfo: MetalPassInfo) throws {
        
        if let inTexture = component.inTexture?.texture{
            
            let commandBuffer = passInfo.getCommandBuffer()
            
            var outTexture: MTLTexture
            if let t = component.outTexture?.texture{
                outTexture = t
            }else{
                guard let t = passInfo.drawable?.texture
                else{
                    print("blit: no out was set and no drawable!")
                    return
                }
                outTexture = t
            }
            
            let inWidth = Double(inTexture.width)
            let inHeight = Double(inTexture.height)
              
            let outWidth = Double(outTexture.width)
            let outHeight = Double(outTexture.height)
            
            var zooming: Double
            
            switch component.type{
            case .fill: zooming = max(outWidth/inWidth,
                                      outHeight/inHeight)
            case .fit: zooming = min(outWidth/inWidth,
                                     outHeight/inHeight)
            case .`default`: zooming = 1
            }
            
            let zoom = component.zoom.wrappedValue
            zooming *= zoom
            
            let scaleX: Double = zooming
            let scaleY: Double = zooming
            let translateX: Double = (outWidth-zooming*inWidth)/2 + component.offset.wrappedValue.width
            let translateY: Double = (outHeight-zooming*inHeight)/2 + component.offset.wrappedValue.height
            
            var scaleTransform = MPSScaleTransform(scaleX: scaleX,
                                                   scaleY: scaleY,
                                                   translateX: translateX,
                                                   translateY: translateY)
            var scl: MPSImageScale
            
            // choose Scaling Method
            switch component.method {
            case .lanczos:
                scl = MPSImageLanczosScale(device: device)
                
            case .bilinear:
                scl = MPSImageBilinearScale(device: device)
                
            //case .nearestNeighbor:  // not implemented!!
            //    scl = MPSImageBilinearScale(device: device)
            }
            
            withUnsafePointer(to: &scaleTransform) { (transformPtr: UnsafePointer<MPSScaleTransform>) -> () in
                scl.scaleTransform = transformPtr
            }
            
            scl.encode(commandBuffer: commandBuffer,
                       sourceTexture: inTexture,
                       destinationTexture: outTexture)
            
        }
    }
}
