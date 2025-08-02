//
//  ColorPickers.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 23.3.25..
//

import SwiftUI
import MetalKit

struct ColorPickerView: View {
    let values: [ObservableValue]
    
    let count: Int
    let title: String
    
    let convertToColorSpace: Color.RGBColorSpace
    
    var body: some View {
        let supportsOpacity = count>3
        let dummyValue: ObservableValue = {
            let binding: SingleValueBinding = (
                    get: { 1 },
                    set: { _ in },
                    defaultValue: { 1 },
                    integer: false)
                return .init(binding: binding, onChange: {_ in })
        }()
        SwiftUIColorPickerView(r: values[0],
                               g: values[1],
                               b: values[2],
                               a: supportsOpacity ? values[3] : dummyValue,
                               supportsOpacity: supportsOpacity,
                               title: title,
                               convertToColorSpace: convertToColorSpace)
    }
}

// This color picker always gives rgb values in pickerColorSpace
// ignoring settings in SwiftUI's ColorPicker view
struct SwiftUIColorPickerView: View{
    
    var r: ObservableValue
    var g: ObservableValue
    var b: ObservableValue
    var a: ObservableValue
    
    let supportsOpacity: Bool
    let title: String
    
    let convertToColorSpace: Color.RGBColorSpace
    
    func setRGBA(){
        let outColor = color.cgColor?.converted(
            to: convertToColorSpace.cgColorSpace,
            intent: .absoluteColorimetric,
            options: nil)
        
        if let rgba = outColor?.float4{
            r.doubleBinding.wrappedValue = Double(rgba.x)
            g.doubleBinding.wrappedValue = Double(rgba.y)
            b.doubleBinding.wrappedValue = Double(rgba.z)
            a.doubleBinding.wrappedValue = Double(rgba.w)
        }
    }
    
    func updateColor(){
        let rgb = {
            let r = Float(r.doubleBinding.wrappedValue)
            let g = Float(g.doubleBinding.wrappedValue)
            let b = Float(b.doubleBinding.wrappedValue)
            return simd_float3([r, g, b])
        }()
        if supportsOpacity{
            let a = Float(a.doubleBinding.wrappedValue)
            let rgba = simd_float4(rgb, a)
            color = rgba.color(convertToColorSpace)
        }else{
            color = rgb.color(convertToColorSpace)
        }
    }
    
    var rgbaChange: Double{
        r.doubleBinding.wrappedValue +
        g.doubleBinding.wrappedValue * 10 +
        b.doubleBinding.wrappedValue * 100 +
        a.doubleBinding.wrappedValue * 1000
    }
    
    @State var color: Color = .black
    
    var body: some View {
        ColorPicker(selection: $color,
                    supportsOpacity: supportsOpacity) {
            SubtitleView(text: title)
        }
        .onChange(of: color, initial: false){
            print("Color: \(color)")
            setRGBA()
        }
        .onChange(of: rgbaChange, initial: false){
            updateColor()
        }
        .onAppear{
            updateColor()
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
        @unknown default:
            fatalError()
        }
    }
}
