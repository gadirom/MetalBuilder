import MetalBuilder
import SwiftUI
import MetalKit


struct Particle: MetalStruct{
    var color: simd_float4 = [0, 0, 0, 0]
    var position: simd_float2 = [0, 0]
    var velocity: simd_float2 = [0, 0]
    var size: Float = 0
    var angle: Float = 0
    var angvelo: Float = 0
}

struct Vertex: MetalStruct
{
    var position: simd_float2 = [0, 0]
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
                )
                .gidIndexType(.uint)
                .bytes(context.$viewportSize)
                .uniforms(u, name: "u")
                .body("""
                //int gidi = int(gid);
                Particle particle = arg.particles.array[gid];
                float2 position = particle.position;
                float pi = 3.14;

                float2 viewport = float2(viewportSize);

                position += particle.velocity*u.speed;
                particle.position = position;

                if (position.x < -viewport.x/2 || position.x > viewport.x/2) particle.velocity.x *= -1.0;
                if (position.y < -viewport.y/2  || position.y > viewport.y/2) particle.velocity.y *= -1.0;

                particle.angle += particle.angvelo;

                if (particle.angle >  pi) { particle.angle -= 2*pi; };
                if (particle.angle < -pi) { particle.angle += 2*pi; };
                
                arg.particles.array[gid] = particle;

                """)
        }
   
    let helpers: String = sincos2
    
    let librarySource = ""

}
