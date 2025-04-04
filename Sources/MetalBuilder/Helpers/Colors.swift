//
//  Colors.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 23.3.25..
//

import MetalKit
import SwiftUI

public extension Color{
    var float3: simd_float3?{
        UIColor(self).float3
    }
    var float4: simd_float4?{
        UIColor(self).float4
    }
}

public extension UIColor{
    var float3: simd_float3?{
        if let c = self.cgColor.components{
            return [Float(c[0]), Float(c[1]), Float(c[2])]
        }else{
            return nil
        }
    }
    var float4: simd_float4?{
        if let c = self.cgColor.components{
            return [Float(c[0]), Float(c[1]), Float(c[2]), Float(c[3])]
        }else{
            return nil
        }
    }
}

public extension simd_float3{
    var color: Color{
        .init(red: CGFloat(self.x),
              green: CGFloat(self.y),
              blue: CGFloat(self.z))
    }
}
public extension simd_float4{
    var color: Color{
        .init(red: CGFloat(self.x),
              green: CGFloat(self.y),
              blue: CGFloat(self.z),
              opacity: CGFloat(self.w))
    }
}
