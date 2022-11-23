import MetalKit

enum UniformsPropertyType: Int{
    case float, float2, float3, float4
    
    var uniformsTypesToMetalType: MetalType{
        let dict: [UniformsPropertyType: MetalType] =
        [
         .float: MetalType(string: "float",
                          length: MemoryLayout<Float>.stride),
        .float2: MetalType(string: "float2",
                           length: MemoryLayout<simd_float2>.stride),
        .float3: MetalType(string: "float3",
                           length: MemoryLayout<simd_float3>.stride),
        .float4: MetalType(string: "float4",
                           length: MemoryLayout<simd_float4>.stride)
    ]
        return dict[self]!
    }
    var uniformsTypesToPackedMetalType: MetalType{
        let dict: [UniformsPropertyType: MetalType] =
    [
         .float: MetalType(string: "float",
                          length: MemoryLayout<Float>.size),
        .float2: MetalType(string: "packed_float2",
                           length: MemoryLayout<simd_packed_float2>.size),
        .float3: MetalType(string: "packed_float3",
                           length: MemoryLayout<simd_packed_float3>.size),
        .float4: MetalType(string: "packed_float4",
                           length: MemoryLayout<simd_packed_float4>.size)
    ]
        return dict[self]!
    }
    
    func metalType(packed: Bool)->MetalType{
        if !packed{
            return uniformsTypesToMetalType
        }else{
            return uniformsTypesToPackedMetalType
        }
    }
    
}
struct MetalType{
    let string: String
    let length: Int
}

//struct Float_3{
//    var x: Float
//    var y: Float
//    var z: Float
//
//    var floatArray: [Float]{
//        [x,y,z]
//    }
//
//    init(_ xyz: [Float]){
//        self.x = xyz[0]
//        self.y = xyz[1]
//        self.z = xyz[2]
//    }
//
//    init(_ xyz: simd_float3){
//        self.x = xyz[0]
//        self.y = xyz[1]
//        self.z = xyz[2]
//    }
//}
//
//extension Float_3: ExpressibleByArrayLiteral
//{
//   init(arrayLiteral: Float...)
//   {
//       self.init(arrayLiteral)
//   }
//}
//
//typealias simd_packed_float3 = Float_3

typealias simd_packed_float3 = MTLPackedFloat3

extension MTLPackedFloat3{
    init(_ xyz: [Float]){
        self = MTLPackedFloat3Make(xyz[0], xyz[1], xyz[2])
    }

    init(_ value: simd_float3){
        self = MTLPackedFloat3Make(value.x, value.y, value.z)
    }
    
    var floatArray: [Float]{
        [x,y,z]
    }
}

extension MTLPackedFloat3: ExpressibleByArrayLiteral
{
    public init(arrayLiteral: Float...)
   {
       self.init(arrayLiteral)
   }
}
