import MetalKit

protocol MetalPass{
    var libraryContainer: LibraryContainer? { get set }
    func setup(renderInfo: GlobalRenderInfo) throws
    func encode(passInfo: MetalPassInfo) throws
}

struct MetalPassInfo {
    let getCommandBuffer: ()->MTLCommandBuffer
    let drawable: CAMetalDrawable?
    let renderPassDescriptor: MTLRenderPassDescriptor
    let restartEncode: () throws ->()
}

struct GlobalRenderInfo{
    var device: MTLDevice
    var depthStencilPixelFormat: MTLPixelFormat?
}
