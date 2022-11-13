import MetalKit
import SwiftUI

enum MetalBuilderRendererError: Error{
    case drawError(String)
}

public final class MetalBuilderRenderer{
    
    var renderData: RenderData!
    
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    
    var startTime: Double = 0
    var pausedTime: Double = 0
    var justStarted = true
    
    var commandBuffer: MTLCommandBuffer!
    
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
    
    convenience init(device: MTLDevice,
                pixelFormat: MTLPixelFormat,
                librarySource: String,
                helpers: String,
                options: MetalBuilderCompileOptions = .default,
                renderingContent: MetalRenderingContent) throws{
        
        self.init()
        
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        let context = MetalBuilderRenderingContext()
        
        do{
        
            renderData = try RenderData(from: renderingContent,
                                        librarySource: librarySource,
                                        helpers: helpers,
                                        options: options,
                                        context: context,
                                        device: device,
                                        pixelFormat: pixelFormat)
            
        }catch{
            print(error)
        }
    }
    func draw(drawable: CAMetalDrawable) throws{
       
        commandBuffer = try startEncode()
        
        if justStarted {
            startTime = CFAbsoluteTimeGetCurrent()
            justStarted = false
        }
        renderData.context.time = Float(CFAbsoluteTimeGetCurrent()-startTime)
        //print(renderData.context.time)
        
        for pass in renderData.passes{
            
            try pass.encode(getCommandBuffer, drawable){
                try restartEncode(commandBuffer: commandBuffer,
                                  drawable: nil)
            }
                
        }

        endEncode(commandBuffer: commandBuffer, drawable: drawable)
    }
    func setScaleFactor(_ sf: Float){
        renderData.context.scaleFactor = sf
    }
    func setSize(size: CGSize){
        renderData.setViewport(size: size, device: device)
    }
    
    func pauseTime(){
        guard !justStarted
        else{return}
        pausedTime = CFAbsoluteTimeGetCurrent()
        print("time paused!")
    }
    func resumeTime(){
        guard !justStarted
        else{return}
        startTime += CFAbsoluteTimeGetCurrent()-pausedTime
        print("time resumed!")
    }
}
