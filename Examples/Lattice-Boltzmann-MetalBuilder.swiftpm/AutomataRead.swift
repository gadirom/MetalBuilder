import MetalBuilder

struct AutomataRead: MetalBuildingBlock{
    var context: MetalBuilderRenderingContext
    var helpers = ""
    var librarySource = automataReadSource
    var compileOptions: MetalBuilderCompileOptions? = nil
    
    var outTexture: MTLTextureContainer
    var obstacleTexture: MTLTextureContainer
    
    var uniforms: UniformsContainer
    
    var metalContent: MetalContent{
        Compute("readAutomata")
            .texture(outTexture, argument: .init(type: "float", access: "read", name: "automata"))
            .texture(obstacleTexture, argument: .init(type: "float", access: "read", name: "obstacle"))
            .drawableTexture(argument: .init(type: "float", access: "write", name: "out"))
            .uniforms(uniforms)
    }
}

let automataReadSource = """
kernel void readAutomata(uint2 gid [[thread_position_in_grid]]){
    
    float2 u = automata.read(gid, 2).gb;
    float c = obstacle.read(gid).r;

    float dfydx = automata.read(gid+uint2(1,0), 2).g-automata.read(gid+uint2(-1,0), 2).g;
    float dfxdy = automata.read(gid+uint2(0,1), 2).b-automata.read(gid+uint2(0,-1), 2).b;
    float curl = dfydx-dfxdy;
    float vel = length(u);
    float h = fract(vel*uni.rainbow+uni.hue);
    float3 colorPos = complColors(h, 0);
    float3 colorNeg = complColors(h, 1);
    float3 colorZero = float3(1);//complColors(h, 2);
    float3 curlColor = curl>0 ? mix(colorZero, colorPos, curl*uni.scale*10.) : mix(colorZero, colorNeg, -curl*uni.scale*10.);
    float3 velColor = vel>0 ? mix(colorZero, colorPos, vel*uni.scale*10.) : mix(colorZero, colorNeg, -vel*uni.scale*10.);//vel*uni.scale*(colorPos+float3(.1));
    float3 color = uni.viewCurl==1 ? curlColor : velColor;
    
    float3 col = c>0.? colorZero*.9 : color;
    
    out.write(float4(pow(col, 1/2.2), 1), gid);
}
"""
