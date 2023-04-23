
import SwiftUI
import MetalKit

/// Declares a render pass encoder
@propertyWrapper
public final class MetalRenderPassEncoder{
    public var wrappedValue: MetalRenderPassEncoderContainer
    
    public var projectedValue: MetalRenderPassEncoderContainer{
        wrappedValue
    }
    
    public init(){
        self.wrappedValue = MetalRenderPassEncoderContainer()
    }
    public init(wrappedValue: MetalRenderPassEncoderContainer, label: String? = nil){
        self.wrappedValue = MetalRenderPassEncoderContainer(label: label)
    }
}

public final class MetalRenderPassEncoderContainer {
    var encoder: MTLRenderCommandEncoder?
    var label: String?
    
    public init(label: String? = nil) {
        self.label = label
    }
}

extension MTLCommandBuffer{
    /// Makes new encoder
    func makeRenderCommandEncoder(renderableData: RenderableData,
              passInfo: MetalPassInfo) -> MTLRenderCommandEncoder?{
        let renderPassDescriptor = passInfo.renderPassDescriptor
        
        //Configuring Render Pass Descriptor
        
        //color attachments
        for key in renderableData.passColorAttachments.keys{
            if let a = renderableData.passColorAttachments[key]?.descriptor{
                if a.texture == nil{
                    a.texture = passInfo.drawable?.texture
                }
                renderPassDescriptor.colorAttachments[key] = a
            }
        }
        
        //stencil attachment
        if let passStencilAttachment = renderableData.passStencilAttachment{
            renderPassDescriptor.stencilAttachment = passStencilAttachment.descriptor
        }else{
            renderPassDescriptor.stencilAttachment = MTLRenderPassStencilAttachmentDescriptor()
        }
        
        //depth attachment
        if let passDepthAttachment = renderableData.passDepthAttachment{
            let descriptor = passDepthAttachment.descriptor
            if descriptor.texture == nil{
                descriptor.texture = passInfo.depthStencilTexture
            }
            renderPassDescriptor.depthAttachment = descriptor
        }
//            else{
//            renderPassDescriptor.stencilAttachment = defaultStencilDescriptor
//        }
        
//        let viewportTexture = renderPassDescriptor.colorAttachments[0].texture!
//
//        renderableData.viewportTextureSize = [viewportTexture.width, viewportTexture.height]
        
        let encoder = self.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        //Viewport
        var viewport: MTLViewport
        if renderableData.viewport == nil{
            let outTexture = renderPassDescriptor.colorAttachments[0].texture!
            
            viewport = MTLViewport(originX: 0.0, originY: 0.0,
                                   width:  Double(outTexture.width),
                                   height: Double(outTexture.height), znear: 0.0, zfar: 1.0)
            encoder?.setViewport(viewport)
        }
        
        return encoder
    }
}

extension MTLRenderCommandEncoder{
    /// Configures an existing encoder
    func configure(renderableData: RenderableData, passInfo: MetalPassInfo){
        
        if let v = renderableData.viewport?.wrappedValue{
            setViewport(v)
        }
        
        //set depth and stencil state
        if let depthStencilState = renderableData.depthStencilState {
            setDepthStencilState(depthStencilState.state)
        }
        
        //set stencil reference value
        if let stencilReferenceValue = renderableData.stencilReferenceValue{
            setStencilReferenceValue(stencilReferenceValue)
        }
    }
}
