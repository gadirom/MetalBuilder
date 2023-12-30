
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
        
        let (renderPassDescriptor, viewport) = passInfo
            .getRenderPassDescriptorAndViewport(renderableData: renderableData)
        
        let encoder = self.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        encoder?.setViewport(viewport)
        
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
        
        if let depthBias = renderableData.depthBias?.wrappedValue {
            setDepthBias(depthBias.depthBias, slopeScale: depthBias.slopeScale, clamp: depthBias.clamp)
        }
        
        //set stencil reference value
        if let stencilReferenceValue = renderableData.stencilReferenceValue{
            setStencilReferenceValue(stencilReferenceValue)
        }
        
        //Face CullMode
        if let cullMode = renderableData.cullMode?.wrappedValue{
            setCullMode(cullMode.mtlCullMode)
            if let frontFacingWinding = cullMode.frontFacingWinding{
                setFrontFacing(frontFacingWinding)
            }
        }
    }
}
