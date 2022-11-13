import MetalKit

protocol MetalPass{
    var libraryContainer: LibraryContainer? { get set }
    func setup(device: MTLDevice) throws
    func encode(_ getCommandBuffer: ()->MTLCommandBuffer,
                _ drawable: CAMetalDrawable?,
                _ restartEncode: () throws ->()) throws
}
