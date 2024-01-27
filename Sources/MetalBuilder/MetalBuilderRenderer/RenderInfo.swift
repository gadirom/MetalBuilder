
import MetalKit

public struct GlobalRenderInfo{
    public init(device: MTLDevice, 
                  depthPixelFormat: MTLPixelFormat? = nil,
                  stencilPixelFormat: MTLPixelFormat? = nil,
                  pixelFormat: MTLPixelFormat) {
        self.device = device
        self.depthPixelFormat = depthPixelFormat
        self.stencilPixelFormat = stencilPixelFormat
        self.pixelFormat = pixelFormat
        self.supportsFamily4 = device.supportsFamily(.apple4)
    }
    
    var device: MTLDevice
    var depthPixelFormat: MTLPixelFormat?
    var stencilPixelFormat: MTLPixelFormat?
    var pixelFormat: MTLPixelFormat
    
    var supportsFamily4: Bool //for non-uniform threads dispatching
}
