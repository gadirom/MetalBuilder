//
//  VideoPlayer.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 14. 11. 2025..
//

import AVFoundation

public enum MetalBuilderVideoPlayerError: Error{
    case couldNotOpenTheFile
}
extension MetalBuilderVideoPlayerError: LocalizedError{
    public var errorDescription: String?{
        switch self {
        case .couldNotOpenTheFile:
            "Could not open the file!"
        }
    }
}

public struct VideoPlayer: MetalBuildingBlock{
    public init(context: MetalBuilderRenderingContext,
                texture: MTLTextureContainer,
                controller: MBVideoController) {
        self.context = context
        self.texture = texture
        self.controller = controller
    }
    
    public var context: MetalBuilderRenderingContext
    
    //Parameters
    let texture: MTLTextureContainer
    
    private let controller: MBVideoController
    
    public var metalContent: MetalContent{
        ManualEncode{ device, _ in
            controller.process(device: device,
                               textureContainer: texture)
        }
    }
}
