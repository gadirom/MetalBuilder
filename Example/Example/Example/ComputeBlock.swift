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

struct ComputeBlock<Particle, Vertex>: MetalBuildingBlock{
    
    let compileOptions: MetalBuilderCompileOptions? = nil //MetalBuilderCompileOptions(mtlCompileOptions: nil, libraryPrefix: .default)
    
    var context: MetalBuilderRenderingContext
    
    //As of Swift 5.6 the arguments of MetalBuffer property wrapper are ignored
    //when the variable is supposed to receive it's value from synthesised init
    @MetalBuffer<Particle>(metalName: "particles") var particlesBuffer
    @MetalBuffer<Vertex>(metalName: "vertices") var vertexBuffer
    
    @MetalBinding var particleScale: Float
    
    let u: UniformsContainer
    
    var metalContent: MetalContent{
            Compute("particleFunction")
                .buffer(particlesBuffer, offset: 0, space: "device", fitThreads: true)
                .buffer(vertexBuffer, offset: 0, space: "device")
                .bytes(context.$viewportSize)
                .bytes($particleScale, name: "scale")
                .uniforms(u)
        }
   
    let helpers: String = sincos2
    
    let librarySource = """

    kernel void particleFunction(uint id [[ thread_position_in_grid ]]){

    Particle particle = particles[id];
    float size = particle.size*scale;
    float angle = particle.angle;
    float2 position = particle.position;
    float4 color = particle.color;

    int j = id * 3;

    vertices[j].color = float4(color.rgb, 0.5);
    vertices[j+1].color = float4((color.rgb + u.color)/2., 0.5);
    vertices[j+2].color = float4(u.color, 1);

    float pi = 3.14;

    float2 scA = sincos2(angle);
    float2 scA23 = sincos2(angle+pi*2/3);
    float2 scA43 = sincos2(angle+pi*4/3);

    vertices[j].position = position + size*scA;
    vertices[j+1].position = position + size*scA23;
    vertices[j+2].position = position + size*scA43;

    float2 viewport = float2(viewportSize);

    position += particle.velocity*u.speed;
    particles[id].position = position;

    if (position.x < -viewport.x/2 || position.x > viewport.x/2) particles[id].velocity.x *= -1.0;
    if (position.y < -viewport.y/2  || position.y > viewport.y/2) particles[id].velocity.y *= -1.0;

    particles[id].angle += particle.angvelo;

    if (particles[id].angle > pi) { particles[id].angle -= 2*pi; };
    if (particles[id].angle < -pi) { particles[id].angle += 2*pi; };

    }

    """
}
