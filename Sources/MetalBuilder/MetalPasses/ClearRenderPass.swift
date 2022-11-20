
class ClearRenderPass: MetalPass{
    var libraryContainer: LibraryContainer?
    
    func setup(renderInfo: GlobalRenderInfo) throws {
    }
    
    func encode(passInfo: MetalPassInfo) throws {
        let commandBuffer = passInfo.getCommandBuffer()
        let renderPassDescriptor =
        passInfo.renderPassDescriptor
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.endEncoding()
    }
}
