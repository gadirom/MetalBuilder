//
//  Math.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 14. 12. 2025..
//

import MetalKit

public extension simd_float3x3{
    static var identity: Self{
        .init(1)
    }
    func transformed2D(_ coord: simd_float2)->simd_float2{
        let coord1: simd_float3 = [coord.x, coord.y, 1]*self
        return [coord1.x, coord1.y]
    }
}

public extension simd_float4x4{
    static var identity: Self{
        .init(1)
    }
}
