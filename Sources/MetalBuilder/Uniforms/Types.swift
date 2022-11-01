import MetalKit

enum UniformsPropertyType: Int{
    case float, float2, float3, float4
}
struct MetalType{
    let string: String
    let length: Int
}

let uniformsTypesToMetalTypes: [UniformsPropertyType: MetalType] = [
    .float: MetalType(string: "float",
                      length: MemoryLayout<Float>.stride),
    .float2: MetalType(string: "float2",
                       length: MemoryLayout<simd_float2>.stride),
    .float3: MetalType(string: "float3",
                       length: MemoryLayout<simd_float3>.stride),
    .float4: MetalType(string: "float4",
                       length: MemoryLayout<simd_float4>.stride)
]
