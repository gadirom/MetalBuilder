import MetalBuilder
import MetalKit

@UniformsStruct
struct UniformsForBlock{
    var property1 = Uniform(simd_float2([1, 0]),    range: 0...1, editable: false)
    var property2 = Uniform(simd_uint3 ([3, 2, 1]), range: 0...10)
}
