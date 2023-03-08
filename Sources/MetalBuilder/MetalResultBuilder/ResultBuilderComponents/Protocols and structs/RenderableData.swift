import MetalKit
import SwiftUI

public struct RenderableData{
    public init(passColorAttachments: [Int : ColorAttachment] = defaultColorAttachments,
                depthStencilDescriptor: MTLDepthStencilDescriptor? = nil,
                passStencilAttachment: StencilAttachment? = nil,
                stencilReferenceValue: UInt32? = nil,
                pipelineColorAttachment: MTLRenderPipelineColorAttachmentDescriptor? = nil) {
        self.passColorAttachments = passColorAttachments
        self.depthStencilDescriptor = depthStencilDescriptor
        self.passStencilAttachment = passStencilAttachment
        self.stencilReferenceValue = stencilReferenceValue
        self.pipelineColorAttachment = pipelineColorAttachment
    }
    
    public var passColorAttachments: [Int: ColorAttachment]
    public var depthStencilDescriptor: MTLDepthStencilDescriptor?
    public var passStencilAttachment: StencilAttachment?
    public var stencilReferenceValue: UInt32?
    public var pipelineColorAttachment: MTLRenderPipelineColorAttachmentDescriptor?
}

public extension RenderableData{
    mutating func apply(_ data: RenderableData){
        self.passColorAttachments = data.passColorAttachments
        if let depthStencilDescriptor = data.depthStencilDescriptor{
            self.depthStencilDescriptor = depthStencilDescriptor
        }
        if let passStencilAttachment = data.passStencilAttachment{
            self.passStencilAttachment = passStencilAttachment
        }
        if let stencilReferenceValue = data.stencilReferenceValue{
            self.stencilReferenceValue = stencilReferenceValue
        }
        if let pipelineColorAttachment = data.pipelineColorAttachment{
            self.pipelineColorAttachment = pipelineColorAttachment
        }
    }
}

/// color attachment with bindings
public struct ColorAttachment{
    public var texture: MTLTextureContainer?
    public var loadAction: Binding<MTLLoadAction>?
    public var storeAction: Binding<MTLStoreAction>?
    public var clearColor: Binding<MTLClearColor>?
    
    var descriptor: MTLRenderPassColorAttachmentDescriptor{
        let d = MTLRenderPassColorAttachmentDescriptor()
        d.texture = texture?.texture
        if let loadAction = loadAction?.wrappedValue{
            d.loadAction = loadAction
        }
        if let storeAction = storeAction?.wrappedValue{
            d.storeAction = storeAction
        }
        if let clearColor = clearColor?.wrappedValue{
            d.clearColor = clearColor
        }
        return d
    }
}
/// default color attachments
public var defaultColorAttachments =
    [0: ColorAttachment(texture: nil,
                       loadAction: Binding<MTLLoadAction>(
                        get: { .clear },
                        set: { _ in }),
                       storeAction: Binding<MTLStoreAction>(
                        get: { .store },
                        set: { _ in }),
                       clearColor: Binding<MTLClearColor>(
                        get: { MTLClearColorMake(0.0, 0.0, 0.0, 1.0)},
                        set: { _ in } )
                       )]
/// stencil attachment
public struct StencilAttachment{
    var texture: MTLTextureContainer?
    var loadAction: Binding<MTLLoadAction>?
    var storeAction: Binding<MTLStoreAction>?
    var clearStencil: Binding<UInt32>?
    var onlyStencil: Bool = false
    
    var descriptor: MTLRenderPassStencilAttachmentDescriptor{
        let d = MTLRenderPassStencilAttachmentDescriptor()
        d.texture = texture?.texture
        if let loadAction = loadAction?.wrappedValue{
            d.loadAction = loadAction
        }
        if let storeAction = storeAction?.wrappedValue{
            d.storeAction = storeAction
        }
        if let clearStencil = clearStencil?.wrappedValue{
            d.clearStencil = clearStencil
        }
        return d
    }
}
