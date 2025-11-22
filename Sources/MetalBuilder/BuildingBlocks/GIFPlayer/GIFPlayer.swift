//
//  GifPlayer.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 21. 11. 2025..
//

import MetalKit
import SwiftUI

public enum MetalBuilderGIFPlayerError: Error{
    case couldNotOpenTheFile
    case couldNotCreateCGImageSource
}
extension MetalBuilderGIFPlayerError: LocalizedError{
    public var errorDescription: String?{
        switch self {
        case .couldNotOpenTheFile:
            "Could not open the file!"
        case .couldNotCreateCGImageSource:
            "Could not create CGImageSource!"
        }
    }
}

public struct GIFPlayer: MetalBuildingBlock{
    public init(context: MetalBuilderRenderingContext,
                texture: MTLTextureContainer,
                controller: GIFPlayerController) {
        self.context = context
        self.texture = texture
        self.controller = controller
    }
    
    public var context: MetalBuilderRenderingContext
    
    private let texture: MTLTextureContainer
    
    private let controller: GIFPlayerController
    
    @MetalState private var lastTime: Float = 0
    
    public var metalContent: MetalContent{
        GIFLoader(context: context,
                  framesTextureArray: controller.framesTextureArray,
                  texture: texture,
                  controller: controller)
        
        EncodeGroup(active: .init{
            let timeInterval = context.time - lastTime
            lastTime = context.time
            return controller.calculateNextFrame(timeInterval)
        }) {
            BlitTexture("CopyGIFFrame")
                .source(controller.framesTextureArray,
                        slice: .init{ controller.currentFrameIndex })
                .destination(texture)
//            ManualEncode{
//                controller.currentFrameIndex = (controller.currentFrameIndex + 1) % framesTextureArray.texture!.arrayLength
//            }
        }
    }
}
