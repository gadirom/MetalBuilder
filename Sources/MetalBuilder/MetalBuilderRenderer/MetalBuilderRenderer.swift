import MetalKit
import SwiftUI

enum MetalBuilderRendererError: Error{
    case drawError(String)
}

public final class MetalBuilderRenderer{
    
    var renderData: RenderData!
    
    unowned var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    
    var commandBuffer: MTLCommandBuffer!
    
    let timer = MetalBuilderTimer()
    
    //depthStencilTexture of the MTKView (if there is any)
    var depthStencilTexture: MTLTexture?
    
    //@MetalState var viewportSize: simd_uint2 = [0, 0]
}

extension MetalBuilderRenderer{
    func getCommandBuffer()->MTLCommandBuffer{
        self.commandBuffer
    }
    func startEncode() throws -> MTLCommandBuffer{
        guard let commandBuffer = commandQueue.makeCommandBuffer()
        else{
            throw MetalBuilderRendererError
                .drawError("No command Buffer!")
        }
        return commandBuffer
    }
    func endEncode(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable?){
        if let drawable = drawable{
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()

        commandBuffer.waitUntilCompleted()
    }
    func restartEncode(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable?) throws{
        endEncode(commandBuffer: commandBuffer, drawable: drawable)
        self.commandBuffer = try startEncode()
    }
}

public extension MetalBuilderRenderer{
    
    convenience init(renderInfo: GlobalRenderInfo,
                     librarySource: String,
                     helpers: String,
                     options: MetalBuilderCompileOptions = .default,
                     renderingContent: MetalBuilderContent,
                     setupFunction: (()->())?,
                     startupFunction: (()->())?) throws{
        
        self.init()
        
        self.device = renderInfo.device
        self.commandQueue = device.makeCommandQueue()
        
        let context = MetalBuilderRenderingContext()
        context.timer = timer
        
        do{
        
            renderData = try RenderData(from: renderingContent,
                                        librarySource: librarySource,
                                        helpers: helpers,
                                        options: options,
                                        context: context,
                                        renderInfo: renderInfo,
                                        setupFunction: setupFunction,
                                        startupFunction: startupFunction)
            
        }catch{
            print(error)
        }
    }
    func draw(drawable: CAMetalDrawable,
              renderPassDescriptor: MTLRenderPassDescriptor) throws{
       
        commandBuffer = try startEncode()
        
        timer.count()
        renderData.context.time = timer.time
        
        for pass in renderData.passes{
            
            let passInfo = MetalPassInfo(getCommandBuffer: getCommandBuffer,
                                         drawable: drawable, depthStencilTexture: depthStencilTexture,
                                         renderPassDescriptor: renderPassDescriptor){
                try self.restartEncode(commandBuffer: self.commandBuffer,
                                       drawable: nil)
            }
            
            try pass.encode(passInfo: passInfo)
                
        }

        endEncode(commandBuffer: commandBuffer, drawable: drawable)
    }
    func setScaleFactor(_ sf: CGFloat){
        renderData.context.setScaleFactor(sf)
    }
    func setSize(size: CGSize){
        renderData.setViewport(size: size, device: device)
    }
    func setDepthStencilTexture(_ texture: MTLTexture?){
        depthStencilTexture = texture
    }
    
    func pauseTime(){
        timer.backgroundPause()
    }
    func resumeTime(){
        timer.backgroundResume()
    }
}
