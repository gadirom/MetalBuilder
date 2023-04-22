import MetalKit

protocol MetalPass{
    var libraryContainer: LibraryContainer? { get set }
    func setup(renderInfo: GlobalRenderInfo) throws
    func encode(passInfo: MetalPassInfo) throws
}

struct MetalPassInfo {
    let getCommandBuffer: ()->MTLCommandBuffer
    let drawable: CAMetalDrawable?
    let depthStencilTexture: MTLTexture?
    let renderPassDescriptor: MTLRenderPassDescriptor
    let restartEncode: () throws ->()
}
