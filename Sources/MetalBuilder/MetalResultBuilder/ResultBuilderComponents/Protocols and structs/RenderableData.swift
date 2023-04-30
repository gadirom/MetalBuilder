import MetalKit
import SwiftUI

public struct RenderableData{
    public init(){
    }
//    public init(passRenderEncoder: MetalRenderPassEncoderContainer? = nil,
//                lastPass: Bool = false,
//                passColorAttachments: [Int : ColorAttachment] = defaultColorAttachments,
//                depthStencilState: MetalDepthStencilStateContainer? = nil,
//                passStencilAttachment: StencilAttachment? = nil,
//                passDepthAttachment: DepthAttachment? = nil,
//                stencilReferenceValue: UInt32? = nil,
//                pipelineColorAttachment: MTLRenderPipelineColorAttachmentDescriptor? = nil,
//                viewport: MetalBinding<MTLViewport>? = nil,
//                depthBias: MetalBinding<DepthBias>? = nil) {
//        self.passRenderEncoder = passRenderEncoder
//        self.lastPass = lastPass
//        self.passColorAttachments = passColorAttachments
//        self.depthStencilState = depthStencilState
//        self.passStencilAttachment = passStencilAttachment
//        self.stencilReferenceValue = stencilReferenceValue
//        self.pipelineColorAttachment = pipelineColorAttachment
//        self.viewport = viewport
//        self.depthBias = depthBias
//    }
    
    public var passRenderEncoder: MetalRenderPassEncoderContainer?
    public var lastPass = false
    public var passColorAttachments: [Int: ColorAttachment] = defaultColorAttachments
    public var depthStencilState: MetalDepthStencilStateContainer?
    public var passStencilAttachment: StencilAttachment?
    public var passDepthAttachment: DepthAttachment?
    public var stencilReferenceValue: UInt32?
    public var pipelineColorAttachment: MTLRenderPipelineColorAttachmentDescriptor?
    public var viewport: MetalBinding<MTLViewport>?
    public var depthBias: MetalBinding<DepthBias>?
    public var cullMode: MetalBinding<CullMode>?
}

public extension RenderableData{
    mutating func apply(_ data: RenderableData){
        self.passRenderEncoder = data.passRenderEncoder
        self.lastPass = data.lastPass
        self.passColorAttachments = data.passColorAttachments
        self.viewport = data.viewport
        if let cullMode = data.cullMode{
            self.cullMode = cullMode
        }
        if let depthBias = data.depthBias{
            self.depthBias = depthBias
        }
        if let depthStencilState = data.depthStencilState{
            self.depthStencilState = depthStencilState
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

/// Stencil attachment
public struct StencilAttachment{
    var texture: MTLTextureContainer?
    var loadAction: Binding<MTLLoadAction>?
    var storeAction: Binding<MTLStoreAction>?
    var clearStencil: Binding<UInt32>?
    //var onlyStencil: Bool = false
    
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

/// Depth attachment
public struct DepthAttachment{
    var texture: MTLTextureContainer?
    var loadAction: Binding<MTLLoadAction>?
    var storeAction: Binding<MTLStoreAction>?
    var clearDepth: Binding<Double>?
    
    var descriptor: MTLRenderPassDepthAttachmentDescriptor{
        let d = MTLRenderPassDepthAttachmentDescriptor()
        if let texture{
            d.texture = texture.texture
        }
        if let loadAction = loadAction?.wrappedValue{
            d.loadAction = loadAction
        }
        if let storeAction = storeAction?.wrappedValue{
            d.storeAction = storeAction
        }
        if let clearDepth = clearDepth?.wrappedValue{
            d.clearDepth = clearDepth
        }
        return d
    }
}

/// Structure for setting depth bias for a render command encoder.
public struct DepthBias{
    var depthBias: Float
    var slopeScale: Float
    var clamp: Float
}

/// Structure that containg face culling information
public struct CullMode{
    var mtlCullMode: MTLCullMode
    var frontFacingWinding: MTLWinding?
}
