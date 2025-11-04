import MetalKit
import SwiftUI

public enum SamplingFilter{
    case linear, nearest
}

public struct QuadRenderer: MetalBuildingBlock, Renderable {
   public init(renderableData: RenderableData = RenderableData(),
               context: MetalBuilderRenderingContext,
               sampleTexture: MTLTextureContainer? = nil,
               filter: SamplingFilter = .linear,
               fragmentShader: FragmentShader? = nil,
               part: QuadPart
    ) {
        
        if let shader = fragmentShader{
            self.quadFragmentShader = shader
        }
        
        self.renderableData = renderableData
        self.context = context
        self.sampleTexture = sampleTexture
        self.part = part
        
        if self.quadFragmentShader == nil{
            self.quadFragmentShader = defaultFragmentShader(filter: filter)
        }
    }
    
    //Renderable Protocol
    public var renderableData: RenderableData
    //
    
    public var context: MetalBuilderRenderingContext
    
    var sampleTexture: MTLTextureContainer! = nil
    
    var part: QuadPart
    
    var quadFragmentShader: FragmentShader!
    
    func defaultFragmentShader(filter: SamplingFilter) -> FragmentShader{
        FragmentShader()
            .body(
        """
            constexpr sampler s(address::clamp_to_zero, filter::\(String(describing: filter)));
            float4 color = inTexture.sample(s, in.uv);
            return color;
        """)
            .texture(sampleTexture, argument: .init(type: "float", access: "sample", name: "inTexture"))
        }
    
    @MetalBuffer<QuadVertex>(metalName: "quadBuffer") var quadBuffer
    
    public func startup(device: MTLDevice){
        try! quadBuffer.create(device: device,
                               fromArray: part.array)
    }
    
    public var metalContent: MetalContent{
        Render("MBQuad",
               type: .triangle,
               count: .constant(6),
               renderableData: renderableData)
            .vertex(VertexShader()
                       .buffer(quadBuffer)
                       //.bytes(context.$viewportToDeviceTransform)
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

public enum QuadPart{
    case up, down, left, right, full
    
    var array:  [QuadVertex]{
        switch self {
        case .up:
            quadVertexArrayUp()
        case .down:
            quadVertexArrayDown()
        case .left:
            quadVertexArrayLeft()
        case .right:
            quadVertexArrayRight()
        case .full:
            quadVertexArrayFull()
        }
    }
}

struct QuadVertex: MetalStruct{
    var coord: simd_float2 = [0, 0]
    var uv: simd_float2 = [0, 0]
}

func quadVertexArrayFull() -> [QuadVertex]{
    [
    .init(coord: [-1,  1], uv: [0,0]),
    .init(coord: [ 1,  1], uv: [1,0]),
    .init(coord: [ 1, -1], uv: [1,1]),
    
    .init(coord: [-1, -1], uv: [0,1]),
    .init(coord: [-1,  1], uv: [0,0]),
    .init(coord: [ 1, -1], uv: [1,1])
    ]
}

func quadVertexArrayUp() -> [QuadVertex]{
    [
    .init(coord: [-1,  1], uv: [0,0]),
    .init(coord: [ 1,  1], uv: [1,0]),
    .init(coord: [ 1,  0], uv: [1,1]),
    
    .init(coord: [-1,  0], uv: [0,1]),
    .init(coord: [-1,  1], uv: [0,0]),
    .init(coord: [ 1,  0], uv: [1,1])
    ]
}
func quadVertexArrayDown() -> [QuadVertex]{
    [
    .init(coord: [-1,  0], uv: [0,0]),
    .init(coord: [ 1,  0], uv: [1,0]),
    .init(coord: [ 1, -1], uv: [1,1]),
    
    .init(coord: [-1, -1], uv: [0,1]),
    .init(coord: [-1,  0], uv: [0,0]),
    .init(coord: [ 1, -1], uv: [1,1])
    ]
}

func quadVertexArrayLeft() -> [QuadVertex]{
    [
    .init(coord: [-1, -1], uv: [0,0]),
    .init(coord: [ 0, -1], uv: [1,0]),
    .init(coord: [ 0,  1], uv: [1,1]),
    
    .init(coord: [-1,  1], uv: [0,1]),
    .init(coord: [-1, -1], uv: [0,0]),
    .init(coord: [ 0,  1], uv: [1,1])
    ]
}
func quadVertexArrayRight() -> [QuadVertex]{
    [
    .init(coord: [ 0, -1], uv: [0,0]),
    .init(coord: [ 1, -1], uv: [1,0]),
    .init(coord: [ 1,  1], uv: [1,1]),
    
    .init(coord: [ 0,  1], uv: [0,1]),
    .init(coord: [ 0, -1], uv: [0,0]),
    .init(coord: [ 1,  1], uv: [1,1])
    ]
}

