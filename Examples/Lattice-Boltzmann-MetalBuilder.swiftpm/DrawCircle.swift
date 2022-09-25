
import MetalBuilder
import MetalKit

struct DrawCircle: MetalBuildingBlock {
    var context: MetalBuilderRenderingContext
    var helpers = ""
    var librarySource = drawCircleSource
    var compileOptions: MetalBuilderCompileOptions? = nil
    
    var outTexture: MTLTextureContainer
    
    @MetalBinding var touchCoord: simd_float2
    
    var uniforms: UniformsContainer
    
    var metalContent: MetalContent{
        Compute("drawCircle")
            .texture(outTexture, argument: .init(type: "float", access: "write", name: "out"))
            .uniforms(uniforms)
            .bytes($touchCoord, name: "touchCoord")
            .bytes(context.$time)
            .bytes(context.$viewportSize)
    }
    
    
}

let drawCircleSource = """
kernel void drawCircle(uint2 gid [[thread_position_in_grid]]){
    float2 fgid = float2(gid);

    float4 color1 = float4(0);
    float msk = 0.;
    float2 m=touchCoord;
    float dst = length(fgid - m);
        if(dst <= uni.radius&&msk==0.) {
            color1 = float4(1);
        }
    out.write(color1, gid);
}
"""
