import MetalKit
import SwiftUI

public struct RenderableData{
    var passColorAttachments: [Int: ColorAttachment] = defaultColorAttachments
    var depthStencilDescriptor: MTLDepthStencilDescriptor?
    var passStencilAttachment: StencilAttachment?
    var stencilReferenceValue: UInt32?
    var pipelineColorAttachment: MTLRenderPipelineColorAttachmentDescriptor?
}

/// color attachment with bindings
public struct ColorAttachment{
    var texture: MTLTextureContainer?
    var loadAction: Binding<MTLLoadAction>?
    var storeAction: Binding<MTLStoreAction>?
    var clearColor: Binding<MTLClearColor>?
    
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