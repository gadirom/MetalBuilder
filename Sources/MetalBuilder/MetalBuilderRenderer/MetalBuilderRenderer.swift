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
    
    //@MetalState var viewportSize: simd_uint2 = [0, 0]
}

extension MetalBuilderRenderer{
    func startEncode() throws -> MTLCommandBuffer{
        guard let commandBuffer = commandQueue.makeCommandBuffer()
        else{
            throw MetalBuilderRendererError
                .drawError("No command Buffer!")
        }
        return commandBuffer
    }
    func endEncode(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable){
        commandBuffer.present(drawable)
        commandBuffer.commit()

        commandBuffer.waitUntilCompleted()
    }
    func restartEncode(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable) throws -> MTLCommandBuffer{
        endEncode(commandBuffer: commandBuffer, drawable: drawable)
        return try startEncode()
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
       
        var commandBuffer = try startEncode()
        
        if justStarted {
            startTime = CFAbsoluteTimeGetCurrent()
            justStarted = false
        }
        renderData.context.time = Float(CFAbsoluteTimeGetCurrent()-startTime)
        print(renderData.context.time)
        
        for pass in renderData.passes{
            if pass.restartEncode{
                commandBuffer = try restartEncode(commandBuffer: commandBuffer,
                                              drawable: drawable)
            }
            try pass.encode(commandBuffer, drawable)
        }

        endEncode(commandBuffer: commandBuffer, drawable: drawable)
    }
    func setScaleFactor(_ sf: Float){
        renderData.context.scaleFactor = sf
    }
    func setSize(size: CGSize){
        renderData.context.viewportSize = simd_uint2([UInt32(size.width), UInt32(size.height)])
        //update textures
        do{
            try renderData.updateTextures(device: device)
        }catch{ print(error) }
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
