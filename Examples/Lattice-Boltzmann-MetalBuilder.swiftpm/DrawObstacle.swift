
import MetalBuilder

struct DrawObstacle: MetalBuildingBlock {
    var context: MetalBuilderRenderingContext
    var helpers = ""
    var librarySource = automataDrawSource
    var compileOptions: MetalBuilderCompileOptions? = nil
    
    var drawTexture: MTLTextureContainer
    @MetalTexture(desc) var tempTexture
    var outTexture: MTLTextureContainer
    
    var uniforms: UniformsContainer
    
    var metalContent: MetalContent{
        BlitTexture()
            .source(outTexture)
            .destination(tempTexture)
        Compute("automataDraw")
            .texture(drawTexture, argument: .init(type: "float", access: "read", name: "draw"))
            .texture(tempTexture, argument: .init(type: "float", access: "read", name: "in"))
            .texture(outTexture, argument: .init(type: "float", access: "write", name: "out"))
            .uniforms(uniforms)
            .bytes(context.$time)
            .bytes(context.$viewportSize)
    }
    
    
}

let automataDrawSource = """
kernel void automataDraw(uint2 gid [[thread_position_in_grid]]){
    //float2 fgid = float2(gid);
    //float2 uv = fgid/float2(viewportSize);
    //uv*=u.texPart;

    float i = in.read(gid).r;
    float a = draw.read(gid).r;

    float4 outColor = uni.draw==1 ? float4(max(a, i)) : float4(min(i, 1-a));

    out.write(outColor, gid);
}
"""
