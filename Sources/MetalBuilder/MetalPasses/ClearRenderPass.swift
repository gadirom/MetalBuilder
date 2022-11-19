
class ClearRenderPass: MetalPass{
    var libraryContainer: LibraryContainer?
    
    func setup(renderInfo: GlobalRenderInfo) throws {
    }
    
    func encode(passInfo: MetalPassInfo) throws {
        let commandBuffer = passInfo.getCommandBuffer()
        let renderPassDescriptor =
        passInfo.renderPassDescriptor
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.endEncoding()
        commandBuffer.present(passInfo.drawable!)
        commandBuffer.commit()
        commandBuffer.waitUntilScheduled()
    }
}
