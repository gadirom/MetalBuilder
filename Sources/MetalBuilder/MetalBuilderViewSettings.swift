
import SwiftUI
import MetalKit

public struct MetalBuilderViewSettings{
    public init(depthStencilPixelFormat: MTLPixelFormat? = nil,
                clearDepth: Double? = nil,
                clearStencil: UInt32? = nil,
                depthStencilAttachmentTextureUsage: MTLTextureUsage? = nil,
                clearColor: MTLClearColor? = nil,
                framebufferOnly: Bool? = nil,
                preferredFramesPerSecond: Int? = nil) {
        self.depthStencilPixelFormat = depthStencilPixelFormat
        self.clearDepth = clearDepth
        self.clearStencil = clearStencil
        self.depthStencilAttachmentTextureUsage = depthStencilAttachmentTextureUsage
        self.clearColor = clearColor
        self.framebufferOnly = framebufferOnly
        self.preferredFramesPerSecond = preferredFramesPerSecond
    }
    var depthStencilPixelFormat: MTLPixelFormat?
    var clearDepth: Double?
    var clearStencil: UInt32?
    
    var depthStencilAttachmentTextureUsage: MTLTextureUsage?
    
    var clearColor: MTLClearColor?
    
    var framebufferOnly: Bool?
    var preferredFramesPerSecond: Int?
}

extension MetalBuilderViewSettings{
    func apply(toView view: MTKView){
        
        if let preferredFramesPerSecond = self.preferredFramesPerSecond{
            view.preferredFramesPerSecond = preferredFramesPerSecond
        }
        
        if let framebufferOnly = self.framebufferOnly{
            view.framebufferOnly = framebufferOnly
        }
       
        if let clearColor = self.clearColor{
            view.clearColor = clearColor
        }
        
        //Depth routine
        if let clearDepth = self.clearDepth{
            view.clearDepth = clearDepth
        }
        if let depthStencilPixelFormat = self.depthStencilPixelFormat{
            view.depthStencilPixelFormat = depthStencilPixelFormat
        }
        //Stencil routine
        if let clearStencil = self.clearStencil{
            view.clearStencil = clearStencil
        }
        if let depthStencilAttachmentTextureUsage = self.depthStencilAttachmentTextureUsage{
            view.depthStencilAttachmentTextureUsage = depthStencilAttachmentTextureUsage
        }
    }
}
