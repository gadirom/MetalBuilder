
import SwiftUI
import MetalKit

public struct MetalBuilderViewSettings{
    public init(depthStencilPixelFormat: MTLPixelFormat? = nil,
                clearDepth: Double? = nil,
                clearColor: MTLClearColor? = nil,
                framebufferOnly: Bool? = nil,
                preferredFramesPerSecond: Int? = nil) {
        self.depthStencilPixelFormat = depthStencilPixelFormat
        self.clearDepth = clearDepth
        self.clearColor = clearColor
        self.framebufferOnly = framebufferOnly
        self.preferredFramesPerSecond = preferredFramesPerSecond
    }
    var depthStencilPixelFormat: MTLPixelFormat?
    var clearDepth: Double?
    
    var clearColor: MTLClearColor?
    
    var framebufferOnly: Bool?
    var preferredFramesPerSecond: Int?
}
