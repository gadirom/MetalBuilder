
import MetalKit

public struct GlobalRenderInfo{
    var device: MTLDevice
    var depthPixelFormat: MTLPixelFormat?
    var stencilPixelFormat: MTLPixelFormat?
    var pixelFormat: MTLPixelFormat
    var supportsFamily4: Bool //for non-uniform threads dispatching
}
