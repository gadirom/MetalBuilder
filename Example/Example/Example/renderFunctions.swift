
public let renderFunctions = """

// Vertex shader outputs and fragment shader inputs
struct RasterizerData{
    float4 position [[position]];
    float4 color; //[[flat]];   // - use this flag to disable color interpolation
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]]){
    RasterizerData out;

    float2 pixelSpacePosition = vertices[vertexID].position.xy;

    float2 viewport = float2(viewportSize);
    
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewport / 2.0);

    out.color = vertices[vertexID].color;

    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]]){
    return in.color;
}

"""
