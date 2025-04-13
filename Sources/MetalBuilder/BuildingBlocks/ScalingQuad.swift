import MetalKit
import SwiftUI

public struct ScalingQuad: MetalBuildingBlock, Renderable {
   public init(renderableData: RenderableData = RenderableData(),
               context: MetalBuilderRenderingContext,
               sampleTexture: MTLTextureContainer,
               fragmentShader: FragmentShader? = nil,
               scaleType: MetalBinding<ScaleType>
    ) {
        
        if let shader = fragmentShader{
            self.quadFragmentShader = shader
        }
        
        self.renderableData = renderableData
        self.context = context
        self.sampleTexture = sampleTexture
        self._scaleType = scaleType
        
        if self.quadFragmentShader == nil{
            self.quadFragmentShader = defaultFragmentShader
        }
    }
    
    //Renderable Protocol
    public var renderableData: RenderableData
    //
    
    public var context: MetalBuilderRenderingContext
    public var helpers = ""
    public var librarySource = ""
    public var compileOptions: MetalBuilderCompileOptions? = nil
    
    var sampleTexture: MTLTextureContainer
    
    @MetalBinding var scaleType: ScaleType
    
    var quadFragmentShader: FragmentShader!
    
    var defaultFragmentShader: FragmentShader{
        FragmentShader()
            .body(
        """
            constexpr sampler s(address::clamp_to_zero, filter::linear);
            float4 color = inTexture.sample(s, in.uv);
            return color;
        """)
            .texture(sampleTexture, argument: .init(type: "float", access: "sample", name: "inTexture"))
        }
    
    @MetalBuffer<QuadVertex>(metalName: "quadBuffer") var quadBuffer
    
    public func startup(device: MTLDevice){
        try! quadBuffer.create(device: device,
                               fromArray: quadVertexArrayFull())
    }
    
    public var metalContent: MetalContent{
        ManualEncode{_, _ in
            let vertices = computeQuadVertices(viewportSize: context.viewportSize,
                                               textureSize: sampleTexture.texture!.size_uint2,
                                               scaleMode: scaleType)
            for i in 0..<vertices.count{
                quadBuffer.pointer![i].coord = vertices[i]
            }
        }
        Render("MBQuad",
               type: .triangle,
               count: .constant(6),
               renderableData: renderableData)
            .vertex(VertexShader()
                       .buffer(quadBuffer)
                       .bytes(context.$viewportToDeviceTransform)
                .vertexOut("""
                float4 position [[position]];
                float2 uv;
            """)
                    .body("""
              auto p = quadBuffer[vertex_id];
              float3 pos = float3(p.coord.xy, 1);
              out.position = float4(pos.xy, 0, 1);
              out.uv = p.uv;
        """))
            .fragment(quadFragmentShader)
    }
}

/// Calculates device coordinates for a quad that fits or fills the texture to the viewport
/// - Parameters:
///   - viewportSize: The size of the viewport as simd_uint2
///   - textureSize: The size of the texture as simd_uint2
///   - scaleMode: Whether to fit (letterboxing) or fill (cropping) the texture
/// - Returns: An array of 4 simd_float2 values representing the quad vertices in device coordinates
public func computeQuadVertices(
    viewportSize: simd_uint2,
    textureSize: simd_uint2,
    scaleMode: ScaleType
) -> [simd_float2] {
    // Convert sizes to float for calculations
    let viewport = simd_float2(Float(viewportSize.x), Float(viewportSize.y))
    let texture = simd_float2(Float(textureSize.x), Float(textureSize.y))
    
    // Calculate aspect ratios
    let viewportAspect = viewport.x / viewport.y
    let textureAspect = texture.x / texture.y
    
    // Calculate scaling factors based on the selected mode
    var scale = simd_float2(1.0, 1.0)
    
    switch scaleMode {
    case .fit:
        if textureAspect > viewportAspect {
            // Texture is wider than viewport (horizontal letterboxing)
            scale.y = (viewport.x / texture.x) * (texture.y / viewport.y)
        } else {
            // Texture is taller than viewport (vertical letterboxing)
            scale.x = (viewport.y / texture.y) * (texture.x / viewport.x)
        }
    case .fill:
        if textureAspect > viewportAspect {
            // Texture is wider than viewport (crop sides)
            scale.x = (viewport.y / texture.y) * (texture.x / viewport.x)
        } else {
            // Texture is taller than viewport (crop top/bottom)
            scale.y = (viewport.x / texture.x) * (texture.y / viewport.y)
        }
    case .default: break
    }
    
    // Calculate the quad vertices in device coordinates (-1 to 1)
    // Order: bottom-left, bottom-right, top-left, top-right
    return [
        simd_float2(-scale.x, scale.y),  // top-left
        simd_float2(scale.x, scale.y),   // top-right
        simd_float2(scale.x, -scale.y),  // bottom-right
        simd_float2(-scale.x, -scale.y), // bottom-left
        simd_float2(-scale.x, scale.y),  // top-left
        simd_float2(scale.x, -scale.y),  // bottom-right
        
    ]
}

// Example usage:
// let viewportSize = simd_uint2(1024, 768)
// let textureSize = simd_uint2(1920, 1080)
// let vertices = computeQuadVertices(viewportSize: viewportSize, textureSize: textureSize, scaleMode: .fit)
