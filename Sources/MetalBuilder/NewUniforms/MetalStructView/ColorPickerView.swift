//
//  ColorPickers.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 23.3.25..
//

import SwiftUI
import MetalKit

// This color picker always gives rgb values in pickerColorSpace
// ignoring settings in SwiftUI's ColorPicker view
struct ColorPickerView: View{
    
    let binding: ValueBinding
    let count: Int
    let title: String
    
    let convertToColorSpace: Color.RGBColorSpace
    
    @State var color: Color = .black
    
    var body: some View {
        let supportsOpacity = count == 4
        ColorPicker(selection: $color,
                    supportsOpacity: supportsOpacity) {
            SubtitleView(text: title)
        }
        .onChange(of: color, initial: false){
            print("Color: \(color)")
            
            let outColor = color.cgColor?.converted(
                to: convertToColorSpace.cgColorSpace,
                intent: .absoluteColorimetric,
                options: nil)
            
            if let rgba = outColor?.float4{
                binding.set(0, rgba.x)
                binding.set(1, rgba.y)
                binding.set(2, rgba.z)
                if supportsOpacity{
                    binding.set(3, rgba.w)
                }
            }
        }
        .onAppear{
            let rgb = {
                let r = Float(binding.get(0))
                let g = Float(binding.get(1))
                let b = Float(binding.get(2))
                return simd_float3([r, g, b])
            }()
            if supportsOpacity{
                let a = Float(binding.get(3))
                let rgba = simd_float4(rgb, a)
                color = rgba.color(convertToColorSpace)
            }else{
                color = rgb.color(convertToColorSpace)
            }
        }
    }
}

extension Color.RGBColorSpace{
    var cgColorSpace: CGColorSpace{
        switch self {
        case .sRGB:
            CGColorSpace(name: CGColorSpace.sRGB)!
        case .sRGBLinear:
            CGColorSpace(name: CGColorSpace.linearSRGB)!
        case .displayP3:
            CGColorSpace(name: CGColorSpace.displayP3)!
        }
    }
}
