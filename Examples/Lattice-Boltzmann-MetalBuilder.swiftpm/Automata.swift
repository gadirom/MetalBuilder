import Foundation
import MetalBuilder
import MetalKit

let automataUniformsDescriptor = UniformsDescriptor()
    .float("radius", range: 1...500, value: 200)
    .float("hue", range: 0...1, value: 0)
    .float("rainbow", range: 0...100, value: 0)
    .float("scale", range: 0...100, value: 1)
    .float("tau", range: 0...10, value: 0.6)
    
    .float("rnd", range: 0...1, value: 0.01)
    .float("force", range: 0...10, value: 2.3)

    .float("draw", range: 0...1, value: 1, show: false)
    .float("viewCurl", range: 0...1, value: 0, show: false)

struct Automata: MetalBuildingBlock {
    var context: MetalBuilderRenderingContext
    let helpers = automataHelpers
    let librarySource = automataSource
    var compileOptions: MetalBuilderCompileOptions? = nil
    
    let uniforms: UniformsContainer
    
    var inTexture: MTLTextureContainer
    var outTexture: MTLTextureContainer
    var obstacleTexture: MTLTextureContainer
    
    var metalContent: MetalContent{
        EncodeGroup{
            Compute("automata")
                .texture(inTexture, argument: .init(type: "float", access: "read", name: "in"))
                .texture(outTexture, argument: .init(type: "float", access: "write", name: "out"))
                .texture(obstacleTexture, argument: .init(type: "float", access: "read", name: "obstacle"), fitThreads: true)
                .bytes(context.$time)
                .bytes(context.$viewportSize)
                .uniforms(uniforms)
            BlitTexture()
                .source(outTexture)
                .destination(inTexture)
                .sliceCount(3)
        }.repeating(2)
    }
}

let automataSource = """
kernel void automata(uint2 gid [[thread_position_in_grid]]){

        //F
        float4 g0 = float4(0);
        float4 g1 = float4(0);
        float4 g2 = float4(0);

        //Drift
        g2.r = in.read(gid, 2).r;
        g0.r = in.read(wrap(gid, -int2(  0,  1 ), viewportSize), 0).r;
        g0.g = in.read(wrap(gid, -int2(  1,  1 ), viewportSize), 0).g;
        g0.b = in.read(wrap(gid, -int2(  1,  0 ), viewportSize), 0).b;
        g0.a = in.read(wrap(gid, -int2(  1, -1 ), viewportSize), 0).a;
        g1.r = in.read(wrap(gid, -int2(  0, -1 ), viewportSize), 1).r;
        g1.g = in.read(wrap(gid, -int2( -1, -1 ), viewportSize), 1).g;
        g1.b = in.read(wrap(gid, -int2( -1,  0 ), viewportSize), 1).b;
        g1.a = in.read(wrap(gid, -int2( -1,  1 ), viewportSize), 1).a;

    //Collision
    float rho = g0.r+g0.g+g0.b+g0.a
               +g1.r+g1.g+g1.b+g1.a+g2.r;
    float2 u;
    u.x =   (        g0.g+g0.b+g0.a     -g1.g-g1.b-g1.a     );
    u.y =   (   g0.r+g0.g     -g0.a-g1.r-g1.g     +g1.a     );
    u /= rho==0. ? 10. : rho;

     //F-equilibrium
     float4 f0 = float4(0);
     float4 f1 = float4(0);
     float4 f2 = float4(0);
     //w * ( 1 + 3*(cx*ux+cy*uy) + 9*(cx*ux+cy*uy)**2/2 - lc
     float C = 4./9., // center weight
           E = 1./9., // edge-neighbors
           V = 1./36.; // vertex-neighbors
     float lc = 1.5*(u.x*u.x+u.y*u.y); // last component is constant

     f0.r = E* (1. + 3.*(u.y) + 4.5*(u.y)*(u.y) - lc);
     f0.g = V* (1. + 3.*(u.x+u.y) + 4.5*(u.x+u.y)*(u.x+u.y) - lc);
     f0.b = E* (1. + 3.*(u.x) + 4.5*(u.x)*(u.x) - lc);
     f0.a = V* (1. + 3.*(u.x-u.y) + 4.5*(u.x-u.y)*(u.x-u.y) - lc);
     f1.r = E* (1. + 3.*(-u.y) + 4.5*(-u.y)*(-u.y) - lc);
     f1.g = V* (1. + 3.*(-u.x-u.y) + 4.5*(-u.x-u.y)*(-u.x-u.y) - lc);
     f1.b = E* (1. + 3.*(-u.x) + 4.5*(-u.x)*(-u.x) - lc);
     f1.a = V* (1. + 3.*(-u.x+u.y) + 4.5*(-u.x+u.y)*(-u.x+u.y) - lc);
     f2.r = C* (1. - lc);

     g0 -= (g0 - f0*rho)/uni.tau;
     g1 -= (g1 - f1*rho)/uni.tau;
     g2 -= (g2 - f2*rho)/uni.tau;

     //apply boundary
     bool b = obstacle.read(gid).r>0.;
     if(b){
        float4 gg0 = g0;
        g0 = g1;
        g1 = gg0;
     }

    g2.yz = u;
    out.write(g0, gid, 0);
    out.write(g1, gid, 1);
    out.write(g2, gid, 2);
}
"""

let automataHelpers = """

uint2 wrap(uint2 p, int2 shift, uint2 size){
    int2 p1 = (int2(p)+shift);// %int2(size);
    //p1.x = p1.x<0 ? size.x-1 : p1.x;
    //p1.x = p1.x>size.x-1 ? 0 : p1.x;
    p1.x = p1.x<0 ? 0 : p1.x;
    p1.x = p1.x>size.x-1 ? size.x-1 : p1.x;

    //p1.y = p1.y<0 ? size.y-1 : p1.y;
    //p1.y = p1.y>size.y-1 ? 0 : p1.y;
    p1.y = p1.y<0 ? 0 : p1.y;
    p1.y = p1.y>size.y-1 ? size.y-1 : p1.y;
    return uint2(p1);
}

float2 hash( float2 p )
{
    p = float2( dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}
float2 hash1(float2 p)
{
    //p = mod(p, 4.0); // tile
    p = float2(dot(p,float2(127.1,311.7)),
               dot(p,float2(269.5,183.3)));
    return fract(sin(p)*18.5453);
}
float3 Hue(float H)
{
    float R = abs(H * 6. - 3.) - 1.;
    float G = 2. - abs(H * 6. - 2.);
    float B = 2. - abs(H * 6. - 4.);
    return clamp(float3(R,G,B), 0., 1.);
}

float3 HSVtoRGB(float3 HSV)
{
    return float3(((Hue(HSV.x) - 1.) * HSV.y + 1.) * HSV.z);
}

float3 complColors(float h, int n){
    float3 col = float3(1);
    if(n==0)col.x = h;
    if(n==1)col.x = fract(h+.33333);
    if(n==2)col.x = fract(h+.6666);
    return HSVtoRGB(col);
}

float sdCircle( float2 p, float r )
{
    return length(p) - r;
}

"""
