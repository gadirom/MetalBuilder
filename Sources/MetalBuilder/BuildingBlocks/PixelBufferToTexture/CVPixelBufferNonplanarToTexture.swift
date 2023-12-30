import SwiftUI
import MetalPerformanceShaders

public struct CVPixelBufferNonplanarToTexture: MetalBuildingBlock{
    public var context: MetalBuilderRenderingContext
    public var helpers = ""
    public var librarySource = ""
    public var compileOptions: MetalBuilderCompileOptions? = nil
    
    @MetalBinding var buffer: CVPixelBuffer?
    @MetalBinding var newTextureIsNeeded: Bool
    
    let texture: MTLTextureContainer
    let pixelFormat: MTLPixelFormat
    
    @MetalState var ready = false
    @MetalState var cacheCreated = false
    
    @MetalState var textureCache: CVMetalTextureCache!
    
    public init(context: MetalBuilderRenderingContext,
                buffer: MetalBinding<CVPixelBuffer?>,
                texture: MTLTextureContainer,
                pixelFormat: MTLPixelFormat,
                createTexture: MetalBinding<Bool>) {
        self.context = context
        self._buffer = buffer
        self.texture = texture
        self._newTextureIsNeeded = createTexture
        self.pixelFormat = pixelFormat
    }
    
    public var metalContent: MetalContent{
        ManualEncode{device, passInfo in
            guard let pixelBuffer = buffer
            else{ return }
            
            if newTextureIsNeeded{
                let size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer),
                                  height: CVPixelBufferGetHeight(pixelBuffer))
                print(size)
                
                let tempTexture = MTLTextureContainer(pixelTextureDesc
                    .pixelFormat(pixelFormat)
                    .usage([.shaderRead, .shaderWrite])
                    .fixedSize(size))
                try? tempTexture.create(device: device, drawable: passInfo.drawable!)
                
                if let texture = tempTexture.texture{
                    self.texture.texture = texture
                    newTextureIsNeeded = false
                }
            }
            if !cacheCreated{
                CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
                cacheCreated = true
            }
            let capturedImageTexture = CVMetalTexture.createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: pixelFormat, textureCache: textureCache, planeIndex: 0)
            if let capturedImageTexture = capturedImageTexture{
                texture.texture = CVMetalTextureGetTexture(capturedImageTexture)
                ready = true
            }
        }
    }
}
