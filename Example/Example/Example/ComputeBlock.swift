import MetalBuilder
import SwiftUI

struct ComputeBlock<Particle, Vertex>: MetalBuildingBlock{
    
    let compileOptions: MetalBuilderCompileOptions? = nil //MetalBuilderCompileOptions(mtlCompileOptions: nil, libraryPrefix: .default)
    
    var context: MetalBuilderRenderingContext
    
    //As of Swift 5.6 the arguments of MetalBuffer property wrapper are ignored
    //when the variable is supposed to receive it's value from synthesised init
    @MetalBuffer<Particle>(metalName: "particles") var particlesBuffer
    @MetalBuffer<Vertex>(metalName: "vertices") var vertexBuffer
    
    @MetalBinding var particleScale: Float
    
    var metalContent: MetalContent{
            Compute("particleFunction")
                .buffer(particlesBuffer, offset: 0, space: "device")
                .buffer(vertexBuffer, offset: 0, space: "device")
                .bytes(context.$viewportSize, space: "constant", type: "uint2",
                                       name: "viewport", index: 2)
                .bytes($particleScale, space: "constant", type: "float",
                                       name: "scale", index: 3)
                .threadsFromBuffer(0)
        }
    
    let librarySource = """

    kernel void particleFunction(uint id [[ thread_position_in_grid ]]){

    Particle particle = particles[id];
    float size = particle.size*scale;
    float angle = particle.angle;
    float2 position = particle.position;
    float4 color = particle.color;

    int j = id * 3;

    vertices[j].color = float4(color.rgb, 0.5);
    vertices[j+1].color = float4(color.rgb * 0.5, 0.5);
    vertices[j+2].color = float4(color.rgb * 0.3, 1);

    float pi = 3.14;

    float sinA = sin(angle);
    float sinA23 = sin(angle+pi*2/3);
    float sinA43 = sin(angle+pi*4/3);
    float cosA = cos(angle);
    float cosA23 = cos(angle+pi*2/3);
    float cosA43 = cos(angle+pi*4/3);

    vertices[j].position = position + float2(size*sinA, size*cosA);
    vertices[j+1].position = position + float2(size*sinA23, size*cosA23);
    vertices[j+2].position = position + float2(size*sinA43, size*cosA43);

    float2 viewportSize = float2(viewport);

    position += particle.velocity;
    particles[id].position = position;

    if (position.x < -viewportSize.x/2 || position.x > viewportSize.x/2) particles[id].velocity.x *= -1.0;
    if (position.y < -viewportSize.y/2  || position.y > viewportSize.y/2) particles[id].velocity.y *= -1.0;

    particles[id].angle += particle.angvelo;

    if (particles[id].angle > pi) { particles[id].angle -= 2*pi; };
    if (particles[id].angle < -pi) { particles[id].angle += 2*pi; };

    }

    """
}
