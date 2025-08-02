//
//  CGColor.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 30. 7. 2025..
//

import CoreGraphics
import simd

func cgColorToRGBA<T: BinaryFloatingPoint>(_ cgColor: CGColor) -> SIMD4<T> {
    // Get the RGB colorspace for conversion
    guard let rgbColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        // Fallback to device RGB if sRGB is not available
        let fallbackColorSpace = CGColorSpaceCreateDeviceRGB()
        return convertToRGBA(cgColor, targetColorSpace: fallbackColorSpace)
    }
    
    return convertToRGBA(cgColor, targetColorSpace: rgbColorSpace)
}

private func convertToRGBA<T: BinaryFloatingPoint>(_ cgColor: CGColor, targetColorSpace: CGColorSpace) -> SIMD4<T> {
    // Convert to target colorspace if needed
    let convertedColor: CGColor
    if let currentColorSpace = cgColor.colorSpace,
       currentColorSpace == targetColorSpace {
        convertedColor = cgColor
    } else {
        convertedColor = cgColor.converted(to: targetColorSpace, intent: .defaultIntent, options: nil) ?? cgColor
    }
    
    // Get the components
    guard let components = convertedColor.components else {
        // Return transparent black as fallback
        return SIMD4<T>(0, 0, 0, 0)
    }
    
    let numComponents = convertedColor.numberOfComponents
    
    // Handle different component counts
    switch numComponents {
    case 1:
        // Grayscale + Alpha
        let gray = T(components[0])
        let alpha = components.count > 1 ? T(components[1]) : T(1.0)
        return SIMD4<T>(gray, gray, gray, alpha)
        
    case 2:
        // Grayscale + Alpha
        let gray = T(components[0])
        let alpha = T(components[1])
        return SIMD4<T>(gray, gray, gray, alpha)
        
    case 3:
        // RGB (no alpha)
        let r = T(components[0])
        let g = T(components[1])
        let b = T(components[2])
        return SIMD4<T>(r, g, b, T(1.0))
        
    case 4:
        // RGBA
        let r = T(components[0])
        let g = T(components[1])
        let b = T(components[2])
        let a = T(components[3])
        return SIMD4<T>(r, g, b, a)
        
    default:
        // Fallback for unexpected component counts
        let r = components.count > 0 ? T(components[0]) : T(0)
        let g = components.count > 1 ? T(components[1]) : T(0)
        let b = components.count > 2 ? T(components[2]) : T(0)
        let a = components.count > 3 ? T(components[3]) : T(1.0)
        return SIMD4<T>(r, g, b, a)
    }
}

// Usage example:
// let color = CGColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.8)
// let rgba = cgColorToRGBA(color)
// print("RGBA: \(rgba.x), \(rgba.y), \(rgba.z), \(rgba.w)")
