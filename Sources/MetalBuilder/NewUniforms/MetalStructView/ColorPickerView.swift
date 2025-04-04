//
//  ColorPickers.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 23.3.25..
//

import SwiftUI
import MetalKit

struct ColorPickerView: View{
    
    let binding: ValueBinding
    let count: Int
    let title: String
    
    @State var color: Color = .black
    
    var body: some View {
        let supportsOpacity = count == 4
        ColorPicker(selection: $color,
                    supportsOpacity: supportsOpacity) {
            SubtitleView(text: title)
        }
        .onChange(of: color, initial: false){
            if let rgba = color.float4{
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
                color = rgba.color
            }else{
                color = rgb.color
            }
        }
    }
}
