import MetalKit
import SwiftUI

public protocol Renderable{
    var toTextureContainer: MTLTextureContainer? { set get }
    
    var depthStencilDescriptor: MTLDepthStencilDescriptor?  { set get }
    
    var passStencilAttachment: StencilAttachment?  { set get }
    
    var stencilReferenceValue: UInt32?  { set get }
    
    var pipelineColorAttachment: MTLRenderPipelineColorAttachmentDescriptor?  { set get }
}

extension Renderable{
    func toTexture(_ container: MTLTextureContainer)->Renderable{
        var r = self
        r.toTextureContainer = container
        return r
    }
    func depthDescriptor(_ descriptor: MTLDepthStencilDescriptor, stencilReferenceValue: UInt32?=nil) -> Renderable{
        var r = self
        r.depthStencilDescriptor = descriptor
        r.stencilReferenceValue = stencilReferenceValue
        return r
    }
    func stencilAttachment(texture: MTLTextureContainer? = nil,
                           loadAction: Binding<MTLLoadAction>? = nil,
                           storeAction: Binding<MTLStoreAction>? = nil,
                           clearStencil: Binding<UInt32>? = nil) -> Renderable{
        var r = self
        let stencilAttachment = StencilAttachment(texture: texture,
                                                  loadAction: loadAction,
                                                  storeAction: storeAction,
                                                  clearStencil: clearStencil)
        r.passStencilAttachment = stencilAttachment
        return r
    }
    func stencilAttachment(_ index: Int = 0,
                          texture: MTLTextureContainer? = nil,
                          loadAction: MTLLoadAction? = nil,
                          storeAction: MTLStoreAction? = nil,
                          clearStencil: UInt32? = nil) -> Renderable{
        var _loadAction: Binding<MTLLoadAction>? = nil
        var _storeAction: Binding<MTLStoreAction>? = nil
        var _clearStencil: Binding<UInt32>? = nil
        if let loadAction = loadAction {
            _loadAction = Binding<MTLLoadAction>.constant(loadAction)
        }
        if let storeAction = storeAction {
            _storeAction = Binding<MTLStoreAction>.constant(storeAction)
        }
        if let clearStencil = clearStencil {
            _clearStencil = Binding<UInt32>.constant(clearStencil)
        }
        return stencilAttachment(texture: texture,
                                 loadAction: _loadAction,
                                 storeAction: _storeAction,
                                 clearStencil: _clearStencil)
    }
    func pipelineColorAttachment(_ descriptor: MTLRenderPipelineColorAttachmentDescriptor) -> Renderable{
        var r = self
        r.pipelineColorAttachment = descriptor
        return r
    }
    
}
