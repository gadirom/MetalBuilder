import MetalKit

protocol MetalPass{
    var libraryContainer: LibraryContainer? { get set }
    func setup(device: MTLDevice) throws
    func encode(passInfo: MetalPassInfo) throws
}

struct MetalPassInfo {
    let getCommandBuffer: ()->MTLCommandBuffer
    let drawable: CAMetalDrawable?
    let renderPassDescriptor: MTLRenderPassDescriptor
    let restartEncode: () throws ->()
}
