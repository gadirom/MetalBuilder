import MetalKit
import SwiftUI

public final class MetalBuilderRenderer{
    
    var renderData: RenderData!
    
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    
    //@MetalState var viewportSize: simd_uint2 = [0, 0]
    
    public init(device: MTLDevice,
                pixelFormat: MTLPixelFormat,
                librarySource: String,
                options: MetalBuilderCompileOptions = .default,
                renderingContent: MetalRenderingContent) throws{
        
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        let context = MetalBuilderRenderingContext()
        
        do{
        
            renderData = try RenderData(from: renderingContent,
                                              librarySource: librarySource,
                                              options: options,
                                              context: context,
                                              device: device,
                                              pixelFormat: pixelFormat)
            
        }catch{
            print(error)
        }
    }
    
    func draw(drawable: CAMetalDrawable) throws{
       
        guard let commandBuffer = commandQueue.makeCommandBuffer()
        else{
            print("no command buffer!")
            return
        }
        for pass in renderData.passes{
            try pass.encode(commandBuffer, drawable)
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()

        commandBuffer.waitUntilCompleted()
        
    }
    func setSize(size: CGSize){
        renderData.context.viewportSize = simd_uint2([UInt32(size.width), UInt32(size.height)])
        //update textures
        do{
            try renderData.updateTextures(device: device)
        }catch{ print(error) }
    }
}
