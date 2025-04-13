import SwiftUI
import MetalPerformanceShaders

public struct CVPixelBufferNonplanarToTexture: MetalBuildingBlock{
    public var context: MetalBuilderRenderingContext
    
    @MetalBinding var buffer: CVPixelBuffer?
    @MetalBinding var newTextureIsNeeded: Bool
    
    let texture: MTLTextureContainer
    let pixelFormat: MTLPixelFormat
    
    @MetalTexture(.init().manual()) var tempTexture
    
    @MetalState private var ready = false
    @MetalState private var cacheCreated = false
    
    @MetalState private var textureCache: CVMetalTextureCache!
    
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
                
                tempTexture.descriptor = pixelTextureDesc
                    .pixelFormat(pixelFormat)
                    .usage([.shaderRead, .shaderWrite])
                    .fixedSize(size)
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
