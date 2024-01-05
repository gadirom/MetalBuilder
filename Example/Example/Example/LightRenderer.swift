
import MetalBuilder
import MetalKit
import SwiftUI

protocol LightProtocol: MetalStruct{
    var coord: simd_float2 {get set}
    var color: simd_float3 {get set}
}

struct Light: LightProtocol{
    var coord: simd_float2 = [0,0]
    var color: simd_float3 = [0,0,0]
}

// Building block for rendering light with SDF
struct LightRenderer: MetalBuildingBlock, Renderable {
    
    static func addUniforms(_ desc: inout UniformsDescriptor){
        desc = desc
            .float("speed", range: 0...100, value: 5)
            .float("len", range: 0...100, value: 20)
            .float("minAng", range: 0...1, value: 0.1)
        
            .float("wosSamples", range: 0...50, value: 1)
            .float("wosSteps", range: 0...50, value: 1)
            .float("wosEpsilon", range: 0...5, value: 0.01)
            .float("Line", range: 0...0.5, value: 0.1)
            
            .float("black", range: 0...100, value: 1)
            .float("adjustE", range: 0...0.1, value: 0.001)
            .float("distrib", range: 0...1, value: 1.0)
                       
            .float("denoise", range: 0...1, value: 0.5)
            .float("dnedge", range: 0...1, value: 0.5)
            .float("dnblur", range: 0...100, value: 5.0)
    }
    
//    public func setup(){
//        var desc = uniforms
//        addUniforms(&<#T##UniformsDescriptor#>)
//    }
    
    let helpers = """
    //constant int   seed = 1;
    //void  srand(int s) { seed = s; }
    int   randi(thread int &seed)  { seed = seed*0x343fd+0x269ec3; return (seed>>16)&32767; }
    float randf(thread int &seed)  { return float(randi(seed))/32767.0; }
    float2  randOnCircle(thread int &seed) { float an=6.2831853*randf(seed); return float2(cos(an),sin(an)); }
    float2  randRotate(float2 n, thread int &seed, float distrib)
    {
        float a = (randf(seed) - 0.5)*2.;
        float an = 6.2831853 * sign(a)*(1.-pow(abs(a), distrib));
        float si = sin(an);
        float co = cos(an);
        float2x2 rot = float2x2(co, -si, si, co);
        return rot*n;
    }
    // hash to initialize the random sequence (copied from Hugo Elias)
    int hash(int n) { n = (n<<13)^n; return n*(n*n*15731+789221)+1376312589; }

    float2 getNormal(float2 p, texture2d<float, access::sample> sdf, sampler s, float ee){
        float d = sdf.sample(s, p).r;
        float2 e = float2(ee, 0.);

        float2 n = d - float2(sdf.sample(s, p - e.xy).r,
                              sdf.sample(s, p - e.yx).r);
        return normalize(-n);
    }

    """
    
    internal var renderableData = RenderableData()
    
    var context: MetalBuilderRenderingContext
    
    var librarySource = ""
    var compileOptions: MetalBuilderCompileOptions? = nil
    
    let sdfTexture: MTLTextureContainer
    let colorTexture: MTLTextureContainer
    
    var uniforms: UniformsContainer
    
    @MetalTexture(TextureDescriptor()
        .manual()) var targetTexture
    
    func startup(device: MTLDevice){
    }
    
    var metalContent: MetalContent{
        ManualEncode{_, passInfo in
            targetTexture.texture = renderableData.passColorAttachments[0]?.texture?.texture ?? passInfo.drawable?.texture
        }
        Compute("walk_on_spheres")
            .texture(colorTexture, argument: .init(type: "float", access: "sample", name: "boundary"))
            .texture(sdfTexture, argument: .init(type: "float", access: "sample", name: "sdf"))
            .texture(targetTexture, argument: .init(type: "float", access: "write", name: "out"), fitThreads: true)
            .bytes(context.$viewportSize)
            .uniforms(uniforms, name: "u")
            .source("""
            kernel void walk_on_spheres(uint2 id [[thread_position_in_grid]]){
                if(id.x>=viewportSize.x||id.y>=viewportSize.y) return;

                constexpr sampler s(address::clamp_to_edge, filter::linear);
                int seed = hash(id.x + viewportSize.x*id.y);
                //thread int seed = se;

                const int kNumSamples = int(u.wosSamples);
                const int   kNumSteps   = int(u.wosSteps);
                const float kEpsilon    = u.wosEpsilon;

                float2 pixel = 1. / float2(viewportSize);

                float3 color = 0.0;

                float r;
                for( int j=0; j<kNumSamples; j++ )
                {
                    float2 q = float2(id);
                    float2 n = getNormal(q*pixel, sdf, s, u.adjustE);

                    //float R;
                    for( int i=0; i<kNumSteps; i++ )
                    {
                        r = sdf.sample(s, q*pixel).r;
                        //if(i==0) R = r;
                        if( r<kEpsilon ) break;
                        
                        float2 nRot = i == 0 ? randOnCircle(seed) : randRotate(n, seed, u.distrib);
                        //float2 nRot = randRotate(n, seed, u.distrib);
                        q += r*nRot;
                    }
                    //if(r < u.edge_s){
                        color += boundary.sample(s, q*pixel).rgb;
                    //}else{
                    //    float2 n = getNormal(float2(id)*pixel, sdf, s);
                     //   float2 uv = (float2(id)+R*n)*pixel;
                     //   color += boundary.sample(s, uv).rgb;
                    //}
                }
                //if(r>u.black){
                //    out.write(float4(0.), id);
                //}else{
                    out.write(float4(color/kNumSamples, 1), id);
                //}
                //out.write(float4(1), id);
                }
            """)
//        MPSUnary {
//            MPSImageGaussianBlur(device: $0, sigma: uniforms.getFloat("dnblur")!)
//        }
//        .source(adjustedTexture)
//        .destination(blurredTexture)
    }
}
