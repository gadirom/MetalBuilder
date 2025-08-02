//
//  Utils.swift
//  Explore Materials
//
//  Created by Roman Gaditskiy on 22. 7. 2025..
//

import MetalKit
import CoreGraphics

public extension MTLTexture {
    
    // MARK: - Pixel Format Info
    
    private var bytesPerPixel: Int {
        switch pixelFormat {
        case .rgba8Unorm, .rgba8Unorm_srgb, .bgra8Unorm, .bgra8Unorm_srgb:
            return 4
//        case .rgb8Unorm, .rgb8Unorm_srgb:
//            return 3
        case .rg8Unorm, .rg8Unorm_srgb:
            return 2
        case .r8Unorm, .r8Unorm_srgb, .a8Unorm:
            return 1
        case .rgba16Unorm, .rgba16Float:
            return 8
        case .rgba32Float:
            return 16
        default:
            return 4 // Default fallback
        }
    }
    
    private var cgPixelFormat: (bitmapInfo: CGBitmapInfo, bitsPerComponent: Int, bitsPerPixel: Int) {
        switch pixelFormat {
        case .rgba8Unorm, .rgba8Unorm_srgb:
            let info = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            return (CGBitmapInfo(rawValue: info), 8, 32)
            
        case .bgra8Unorm, .bgra8Unorm_srgb:
            let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            return (CGBitmapInfo(rawValue: info), 8, 32)
            
//        case .rgb8Unorm, .rgb8Unorm_srgb:
//            let info = CGImageAlphaInfo.none.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
//            return (CGBitmapInfo(rawValue: info), 8, 24)
            
        case .rg8Unorm, .rg8Unorm_srgb:
            // RG formats need special handling - convert to RGB
            let info = CGImageAlphaInfo.none.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            return (CGBitmapInfo(rawValue: info), 8, 24)
            
        case .r8Unorm, .r8Unorm_srgb, .a8Unorm:
            // Single channel - treat as grayscale
            let info = CGImageAlphaInfo.none.rawValue
            return (CGBitmapInfo(rawValue: info), 8, 8)
            
        case .rgba16Unorm:
            let info = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder16Big.rawValue
            return (CGBitmapInfo(rawValue: info), 16, 64)
            
        default:
            // Default to BGRA8
            let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            return (CGBitmapInfo(rawValue: info), 8, 32)
        }
    }
    
    private var colorSpace: CGColorSpace {
        switch pixelFormat {
        case .rgba8Unorm_srgb, .bgra8Unorm_srgb, .rg8Unorm_srgb, .r8Unorm_srgb:
            return CGColorSpaceCreateDeviceRGB()
        case .r8Unorm, .a8Unorm:
            return CGColorSpaceCreateDeviceGray()
        default:
            return CGColorSpaceCreateDeviceRGB()
        }
    }
    
    // MARK: - Bytes Extraction
    
    func bytes() -> UnsafeMutableRawPointer {
        let width = self.width
        let height = self.height
        let bytesPerPixel = self.bytesPerPixel
        let rowBytes = width * bytesPerPixel
        let totalBytes = width * height * bytesPerPixel
        
        let p = malloc(totalBytes)!
        getBytes(p, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        return p
    }
    
    // MARK: - Image Conversion
    
    func toImage() -> CGImage? {
//        let width = self.width
//        let height = self.height
//        let bytesPerPixel = self.bytesPerPixel
        
        // Handle special cases that need pixel format conversion
        switch pixelFormat {
        case .rg8Unorm, .rg8Unorm_srgb:
            return toImageFromRG()
        case .r8Unorm, .r8Unorm_srgb, .a8Unorm:
            return toImageFromSingleChannel()
        default:
            return toImageDirect()
        }
    }
    
    private func toImageDirect() -> CGImage? {
        let p = self.bytes()
        let width = self.width
        let height = self.height
        let bytesPerPixel = self.bytesPerPixel
        let rowBytes = width * bytesPerPixel
        let totalBytes = width * height * bytesPerPixel
        
        let formatInfo = cgPixelFormat
        let colorSpace = self.colorSpace
        
        if let provider = CGDataProvider(dataInfo: nil, data: p, size: totalBytes, releaseData: { _, p, _ in
            p.deallocate()
        }) {
            return CGImage(width: width,
                          height: height,
                          bitsPerComponent: formatInfo.bitsPerComponent,
                          bitsPerPixel: formatInfo.bitsPerPixel,
                          bytesPerRow: rowBytes,
                          space: colorSpace,
                          bitmapInfo: formatInfo.bitmapInfo,
                          provider: provider,
                          decode: nil,
                          shouldInterpolate: true,
                          intent: .defaultIntent)
        }
        return nil
    }
    
    private func toImageFromRG() -> CGImage? {
        let p = self.bytes()
        let width = self.width
        let height = self.height
        let totalPixels = width * height
        
        // Convert RG to RGB by duplicating G channel as B
        let rgbData = malloc(totalPixels * 3)!.assumingMemoryBound(to: UInt8.self)
        let rgData = p.assumingMemoryBound(to: UInt8.self)
        
        for i in 0..<totalPixels {
            let rgIndex = i * 2
            let rgbIndex = i * 3
            rgbData[rgbIndex] = rgData[rgIndex]         // R
            rgbData[rgbIndex + 1] = rgData[rgIndex + 1] // G
            rgbData[rgbIndex + 2] = rgData[rgIndex + 1] // G as B
        }
        
        p.deallocate() // Clean up original data
        
        let rowBytes = width * 3
        let totalBytes = totalPixels * 3
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        
        if let provider = CGDataProvider(dataInfo: nil, data: rgbData, size: totalBytes, releaseData: { _, p, _ in
            p.deallocate()
        }) {
            return CGImage(width: width,
                          height: height,
                          bitsPerComponent: 8,
                          bitsPerPixel: 24,
                          bytesPerRow: rowBytes,
                          space: CGColorSpaceCreateDeviceRGB(),
                          bitmapInfo: bitmapInfo,
                          provider: provider,
                          decode: nil,
                          shouldInterpolate: true,
                          intent: .defaultIntent)
        }
        return nil
    }
    
    private func toImageFromSingleChannel() -> CGImage? {
        let p = self.bytes()
        let width = self.width
        let height = self.height
        let rowBytes = width
        let totalBytes = width * height
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        
        if let provider = CGDataProvider(dataInfo: nil, data: p, size: totalBytes, releaseData: { _, p, _ in
            p.deallocate()
        }) {
            return CGImage(width: width,
                          height: height,
                          bitsPerComponent: 8,
                          bitsPerPixel: 8,
                          bytesPerRow: rowBytes,
                          space: CGColorSpaceCreateDeviceGray(),
                          bitmapInfo: bitmapInfo,
                          provider: provider,
                          decode: nil,
                          shouldInterpolate: true,
                          intent: .defaultIntent)
        }
        return nil
    }
    
    // MARK: - Convenience Methods
    
    /// Convert texture to image with explicit pixel format handling
//    func toImage(assumingFormat format: MTLPixelFormat) -> CGImage? {
//        let originalFormat = self.pixelFormat
//        // Temporarily override the pixel format for conversion
//        // Note: This is conceptual - you'd need to create a new texture or handle differently
//        return toImage()
//    }
    
    /// Check if the texture format is supported for direct conversion
    var isDirectlyConvertible: Bool {
        switch pixelFormat {
        case .rgba8Unorm, .rgba8Unorm_srgb, .bgra8Unorm, .bgra8Unorm_srgb,
             .rg8Unorm, .rg8Unorm_srgb,
             .r8Unorm, .r8Unorm_srgb, .a8Unorm, .rgba16Unorm:
            return true
        default:
            return false
        }
    }
}

