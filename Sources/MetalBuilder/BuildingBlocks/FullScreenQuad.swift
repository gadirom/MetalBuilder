import MetalKit
import SwiftUI

/// Building block for rendering full screen quad
public struct FullScreenQuad: MetalBuildingBlock, Renderable {
    /// Creates a new building block that renders full scrwwn quad.
    /// - Parameters:
    ///   - renderableData: renderable data struct. Pass the `renderableData` property of your building block.
    ///   - context: rendering context that you get from `MetalBuilderView`.
    ///   - sampleTexture: texture to sample if you whant to use built-in fragment shader.
    ///   - fragmentShader: fragment shader for the quad.
    public init(renderableData: RenderableData = RenderableData(),
                context: MetalBuilderRenderingContext,
                sampleTexture: MTLTextureContainer? = nil,
                fragmentShader: FragmentShader? = nil) {
        
        if let shader = fragmentShader{
            self.quadFragmentShader = shader
        }
        
        self.renderableData = renderableData
        self.context = context
        self.sampleTexture = sampleTexture
        self.quadBuffer = quadBuffer
        
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
    
    var sampleTexture: MTLTextureContainer! = nil
    
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
    
    @MetalBuffer<FullScreenQuadVertex>(metalName: "quadBuffer",
                                       fromArray: quadVertexArray()) var quadBuffer
    
    public var metalContent: MetalContent{
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
              return out;
        """))
            .fragment(quadFragmentShader)
    }
}

struct FullScreenQuadVertex: MetalStruct{
    var coord: simd_float2 = [0, 0]
    var uv: simd_float2 = [0, 0]
}

func quadVertexArray() -> [FullScreenQuadVertex]{
    [
    .init(coord: [-1,  1], uv: [0,0]),
    .init(coord: [ 1,  1], uv: [1,0]),
    .init(coord: [ 1, -1], uv: [1,1]),
    
    .init(coord: [-1, -1], uv: [0,1]),
    .init(coord: [-1,  1], uv: [0,0]),
    .init(coord: [ 1, -1], uv: [1,1])
    ]
}
