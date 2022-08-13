
import MetalKit
import MetalBuilder

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
