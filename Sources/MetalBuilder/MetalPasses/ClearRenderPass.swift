
class ClearRenderPass: MetalPass{
    
    let component: ClearRender
    
    var libraryContainer: LibraryContainer?
    
    init(_ component: ClearRender){
        self.component = component
    }
    
    func setup(renderInfo: GlobalRenderInfo) throws {
    }
    
    func encode(passInfo: MetalPassInfo) throws {
        let commandBuffer = passInfo.getCommandBuffer()
        let renderPassDescriptor =
        passInfo.renderPassDescriptor
        if let clearColor = component.clearColor{
            renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        }
        if let texture = component.texture?.texture{
            renderPassDescriptor.colorAttachments[0].texture = texture
        }
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.endEncoding()
    }
}
