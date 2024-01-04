import MetalBuilder
import SwiftUI
import MetalKit


struct Particle: MetalStruct{
    var position: simd_float3 = [0, 0, 0]
    var color: simd_float4 = [0, 0, 0, 0]
    var velocity: simd_float2 = [0, 0]
    var size: Float = 0
    var angle: Float = 0
    var angvelo: Float = 0
}

struct Vertex: MetalStruct
{
    var position: simd_float3 = [0, 0, 0]
    var color: simd_float4 = [0, 0, 0, 0]
}

let sincos2 = """
        float2 sincos2(float a){
                     float cosa;
                     float sina = sincos(a, cosa);
                     return float2(sina, cosa);
        }
"""

struct ComputeBlock: MetalBuildingBlock{
    
    let compileOptions: MetalBuilderCompileOptions? = nil //MetalBuilderCompileOptions(mtlCompileOptions: nil, libraryPrefix: .default)
    
    var context: MetalBuilderRenderingContext
    
    let u: UniformsContainer
    
    //As of Swift 5.6 the arguments of MetalBuffer property wrapper are ignored
    //when the variable is supposed to receive it's value from synthesised init
    //@MetalBuffer<Particle>(metalName: "particles") var particlesBuffer
    //@MetalBuffer<Vertex>(metalName: "vertices") var vertexBuffer
    
    //@MetalBinding var particleScale: Float
    
    var argBuffer: ArgumentBuffer
    
//    var argBuffer1: ArgumentBuffer{
//        .new("argBuffer1", desc:
//            ArgumentBufferDescriptor("MyArgBuffer1")
//                .buffer(particlesBuffer, name: "particles", space: "device")
//                .buffer(vertexBuffer, name: "vertices", space: "device")
//        )
//    }
    
    var metalContent: MetalContent{
            Compute("integrate")
                .argBuffer(argBuffer, name: "arg", UseResources()
                    .buffer("particles", usage: [.read, .write], fitThreads: true)
                    .buffer("vertices", usage: [.write])
                )
                .gidIndexType(.uint)
                .bytes(context.$viewportSize)
                .uniforms(u, name: "u")
                .body("""
                //int gidi = int(gid);
                Particle particle = arg.particles.array[gid];
                float2 position = particle.position.xy;
                float pi = 3.14;

                float2 viewport = float2(viewportSize);

                position += particle.velocity*u.speed;
                particle.position.xy = position;

                if (position.x < -viewport.x/2 || position.x > viewport.x/2) particle.velocity.x *= -1.0;
                if (position.y < -viewport.y/2  || position.y > viewport.y/2) particle.velocity.y *= -1.0;

                particle.angle += particle.angvelo;

                if (particle.angle >  pi) { particle.angle -= 2*pi; };
                if (particle.angle < -pi) { particle.angle += 2*pi; };
                
                arg.particles.array[gid] = particle;
                
                                        
                float size = particle.size;
                float angle = particle.angle;
                float4 color = particle.color;
                
                for(short i=0;i<3;i++){
                
                    switch(i){
                    case 0: color = float4(color.rgb, 0.5); break;
                    case 1: color = float4((color.rgb + u.color)/2., 0.5); break;
                    case 2: color = float4(u.color, 1);
                    }
                    
                    float pi = 3.14;
                    
                    float2 scA = sincos2(angle+pi*2/3*float(i));
                    
                    Vertex v;
                    v.position.xy = position + size*scA;
                    v.position.z = 0.;
                    v.color = color;
                    arg.vertices[gid*3+i] = v;
                }

                """)
        }
   
    let helpers: String = sincos2
    
    let librarySource = ""

}
