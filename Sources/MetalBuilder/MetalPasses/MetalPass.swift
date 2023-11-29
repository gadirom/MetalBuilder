import MetalKit

protocol MetalPass{
    var libraryContainer: LibraryContainer? { get set }
    func setup(renderInfo: GlobalRenderInfo) throws
    func prerun(renderInfo: GlobalRenderInfo) throws
    func encode(passInfo: MetalPassInfo) throws
}
extension MetalPass{
    func prerun(renderInfo: GlobalRenderInfo) throws{
    }
}

struct MetalPassInfo {
    let getCommandBuffer: ()->MTLCommandBuffer
    let drawable: CAMetalDrawable?
    let depthStencilTexture: MTLTexture?
    let renderPassDescriptor: MTLRenderPassDescriptor
    let restartEncode: () throws ->()
}
