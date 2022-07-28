
public let metalFunctions = """

#include <metal_stdlib>

using namespace metal;

struct Particle{
    float4 color;
    float2 position;
    float2 velocity;
     float size;
     float angle;
     float angvelo;
};

struct Vertex{
    vector_float2 position;
    vector_float4 color;
};

// Vertex shader outputs and fragment shader inputs
struct RasterizerData{
    float4 position [[position]];
    float4 color; //[[flat]];   // - use this flag to disable color interpolation
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]]){
    RasterizerData out;

    float2 pixelSpacePosition = vertices[vertexID].position.xy;

    float2 viewportSize = float2(viewport);
    
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);

    // Pass the input color directly to the rasterizer.
    out.color = vertices[vertexID].color;

    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]]){
    // Return the interpolated color.
    return in.color;
}

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
