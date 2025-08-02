//
//  MetalStarter.swift
//  Explore Materials
//
//  Created by Roman Gaditskiy on 22. 7. 2025..
//

import MetalKit

open class MetalStarter<Block: MetalBuildingBlock>{
    var renderer: MetalBuilderRenderer!
    public var device: MTLDevice!
    open func initBlock(context: MetalBuilderRenderingContext) -> (Block?){
        nil
    }

    public func start() throws{
        try renderer.draw(drawable: nil,
                          renderPassDescriptor: .init())
    }
    
    public init(){
        let device = MTLCreateSystemDefaultDevice()!
        
        self.device = device
        
        renderer = try! MetalBuilderRenderer(
            renderInfo: .init(device: device,
                              depthPixelFormat: nil,
                              stencilPixelFormat: nil,
                              pixelFormat: .rgba8Unorm),
            librarySource: "",
            helpers: "",
            options: .default,
            renderingContent: { context in
                initBlock(context: context)!
            },
            setupFunction: nil,
            startupFunction: nil)
        
        renderer.setSize(size: .zero)
    }
}
