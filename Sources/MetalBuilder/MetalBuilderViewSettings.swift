
import SwiftUI
import MetalKit

public struct MetalBuilderViewSettings{
    var onResizeCode: ((CGSize)->())?
    
    var depthStencilPixelFormat: MTLPixelFormat?
    var clearDepth: Double?
    
    var clearColor: MTLClearColor?
    
    var framebufferOnly: Bool?
    var preferredFramesPerSecond: Int?
}
