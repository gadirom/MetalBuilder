//
//  ImageMetadata.swift
//  Explore Materials
//
//  Created by Roman Gaditskiy on 22. 7. 2025..
//

import CoreGraphics
import ImageIO
import Foundation

public enum ImageMetadataError: Error{
    case fileError
    case convertToImageError
}

public struct ImageMetadata {

    public var imageProperties : [CFString: Any]

    public init(url: URL) throws {
        
        let data = try Data(contentsOf: url)
                
        let options = [kCGImageSourceShouldCache: kCFBooleanFalse]
        if let imageSource = CGImageSourceCreateWithData(data as CFData, options as CFDictionary),
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] {
            self.imageProperties = imageProperties
        } else {
            throw ImageMetadataError.fileError
        }
    }

    public var dpi : Int? { imageProperties[kCGImagePropertyDPIWidth] as? Int }
    public var width : Int? { imageProperties[kCGImagePropertyPixelWidth] as? Int }
    public var height : Int? { imageProperties[kCGImagePropertyPixelHeight] as? Int }

}
