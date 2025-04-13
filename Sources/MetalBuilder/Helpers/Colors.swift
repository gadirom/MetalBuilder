
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
    var float4: simd_float4?{
        self.cgColor.float4
    }
    var float3: simd_float3?{
        self.cgColor.float3
    }
}
public extension CGColor{
    var float4: simd_float4?{
        if let c = self.components{
            return [Float(c[0]), Float(c[1]), Float(c[2]), Float(c[3])]
        }else{
            return nil
        }
    }
    var float3: simd_float3?{
        if let c = self.components{
            return [Float(c[0]), Float(c[1]), Float(c[2])]
        }else{
            return nil
        }
    }
    var half4: simd_half4?{
        if let c = self.components{
            return [Float16(c[0]), Float16(c[1]), Float16(c[2]), Float16(c[3])]
        }else{
            return nil
        }
    }
    var half3: simd_half3?{
        if let c = self.components{
            return [Float16(c[0]), Float16(c[1]), Float16(c[2])]
        }else{
            return nil
        }
    }
}

public extension SIMD4 where Scalar: BinaryFloatingPoint {
    func uiColor(_ colorSpace: CGColorSpace) -> UIColor{
        if let cgColor = self.cgColor(colorSpace){
            return .init(cgColor: cgColor)
        }else{
            return UIColor()
        }
    }
    func cgColor(_ colorSpace: CGColorSpace) -> CGColor?{
        var components = [CGFloat(x), CGFloat(y), CGFloat(z), CGFloat(w)]
        return CGColor(colorSpace: colorSpace, components: &components)
    }
    func color(_ colorSpace: Color.RGBColorSpace) -> Color{
        .init(colorSpace,
              red: Double(self.x),
              green: Double(self.y),
              blue: Double(self.z),
              opacity: Double(self.w))
    }
    var mtlClearColor: MTLClearColor{
        .init(red: Double(x), green: Double(y), blue: Double(z), alpha: Double(w))
    }
}

public extension SIMD3 where Scalar: BinaryFloatingPoint {
    func uiColor(_ colorSpace: CGColorSpace) -> UIColor{
        if let cgColor = self.cgColor(colorSpace){
            return .init(cgColor: cgColor)
        }else{
            return UIColor()
        }
    }
    func cgColor(_ colorSpace: CGColorSpace) -> CGColor?{
        var components = [CGFloat(x), CGFloat(y), CGFloat(z), CGFloat(1)]
        return CGColor(colorSpace: colorSpace, components: &components)
    }
    func color(_ colorSpace: Color.RGBColorSpace) -> Color{
        .init(colorSpace,
              red: Double(self.x),
              green: Double(self.y),
              blue: Double(self.z))
    }
    var mtlClearColor: MTLClearColor{
        .init(red: Double(x), green: Double(y), blue: Double(z), alpha: Double(1))
    }
}

