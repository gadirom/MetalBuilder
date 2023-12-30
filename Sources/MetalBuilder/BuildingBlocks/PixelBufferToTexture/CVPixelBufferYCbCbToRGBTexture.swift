import SwiftUI
import MetalPerformanceShaders

let pixelTextureDesc = TextureDescriptor()

public struct CVPixelBufferYCbCbToRGBTexture: MetalBuildingBlock{
    public var context: MetalBuilderRenderingContext
    public var helpers = ""
    public var librarySource = ""
    public var compileOptions: MetalBuilderCompileOptions? = nil
    
    @MetalBinding var buffer: CVPixelBuffer?
    @MetalBinding var newTextureIsNeeded: Bool
    let texture: MTLTextureContainer
    
    @MetalTexture(pixelTextureDesc) var textureY
    @MetalTexture(pixelTextureDesc) var textureCbCr
    
    @MetalState var ready = false
    @MetalState var cacheCreated = false
    
    @MetalState var textureCache: CVMetalTextureCache!
    
    public init(context: MetalBuilderRenderingContext,
                buffer: MetalBinding<CVPixelBuffer?>,
                texture: MTLTextureContainer,
                createTexture: MetalBinding<Bool>) {
        self.context = context
        self._buffer = buffer
        self.texture = texture
        self._newTextureIsNeeded = createTexture
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
            let capturedImageTextureY = CVMetalTexture.createTexture(fromPixelBuffer: pixelBuffer, pixelFormat:.r8Unorm, textureCache: textureCache, planeIndex:0)
            let capturedImageTextureCbCr = CVMetalTexture.createTexture(fromPixelBuffer: pixelBuffer, pixelFormat:.rg8Unorm, textureCache: textureCache, planeIndex:1)
            if let capturedImageTextureY = capturedImageTextureY,
               let capturedImageTextureCbCr = capturedImageTextureCbCr{
                textureY.texture = CVMetalTextureGetTexture(capturedImageTextureY)
                textureCbCr.texture = CVMetalTextureGetTexture(capturedImageTextureCbCr)
                ready = true
            }
        }
        EncodeGroup(active: $ready){
            Compute("convertCVPixelBufferPlanesToTexture")
                .texture(textureY, argument: .init(type: "float", access: "sample", name: "textureY"))
                .texture(textureCbCr, argument: .init(type: "float", access: "sample", name: "textureCbCr"))
                .texture(texture, argument: .init(type: "float", access: "write", name: "out"), fitThreads: true)
                .source("""
                kernel void convertCVPixelBufferPlanesToTexture(uint2 gid [[thread_position_in_grid]],
                                                                  uint2 size [[threads_per_grid]]){
                
                    float2 uv = float2(gid)/float2(size);
                    
                    constexpr sampler colorSampler(mip_filter::linear,
                                                   mag_filter::linear,
                                                   min_filter::linear);
                    
                    const float4x4 ycbcrToRGBTransform = float4x4(
                        float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
                        float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
                        float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
                        float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
                    );
                        
                    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
                    float4 ycbcr = float4(textureY.sample(colorSampler, uv).r,
                                          textureCbCr.sample(colorSampler, uv).rg, 1.0);
                        
                    // Return converted RGB color
                    float4 col = ycbcrToRGBTransform * ycbcr;
                    out.write(col, gid);
                }
                """)
        }
    }
}
