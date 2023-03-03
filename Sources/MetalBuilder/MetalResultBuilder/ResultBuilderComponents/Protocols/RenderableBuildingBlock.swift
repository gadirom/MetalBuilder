import MetalKit
import SwiftUI

public protocol RenderableBuildingBlock: MetalBuildingBlock{
    var toTextureContainer: MTLTextureContainer? { set get }
    
    var passColorAttachments: [Int: ColorAttachment] { set get }
    
    var depthStencilDescriptor: MTLDepthStencilDescriptor?  { set get }
    
    var passStencilAttachment: StencilAttachment?  { set get }
    
    var stencilReferenceValue: UInt32?  { set get }
    
    var pipelineColorAttachment: MTLRenderPipelineColorAttachmentDescriptor?  { set get }
}

public extension RenderableBuildingBlock{
    func toTexture(_ container: MTLTextureContainer?)->Self{
        var r = self
        r.toTextureContainer = container
        return r
    }
    func depthDescriptor(_ descriptor: MTLDepthStencilDescriptor, stencilReferenceValue: UInt32?=nil) -> Self{
        var r = self
        r.depthStencilDescriptor = descriptor
        r.stencilReferenceValue = stencilReferenceValue
        return r
    }
    func stencilAttachment(_ attachement: StencilAttachment?) -> Self{
        var r = self
        r.passStencilAttachment = attachement
        return r
    }
    func stencilAttachment(texture: MTLTextureContainer? = nil,
                           loadAction: Binding<MTLLoadAction>? = nil,
                           storeAction: Binding<MTLStoreAction>? = nil,
                           clearStencil: Binding<UInt32>? = nil) -> Self{
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
                          clearStencil: UInt32? = nil) -> Self{
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
    func pipelineColorAttachment(_ descriptor: MTLRenderPipelineColorAttachmentDescriptor?) -> Self{
        var r = self
        r.pipelineColorAttachment = descriptor
        return r
    }
    
    func colorAttachement(_ index: Int = 0,
                          texture: MTLTextureContainer? = nil,
                          loadAction: Binding<MTLLoadAction>? = nil,
                          storeAction: Binding<MTLStoreAction>? = nil,
                          mtlClearColor: Binding<MTLClearColor>? = nil) -> Self{
        var r = self
        let colorAttachement = ColorAttachment(texture: texture,
                                               loadAction: loadAction,
                                               storeAction: storeAction,
                                               clearColor: mtlClearColor)
        r.passColorAttachments[index] = colorAttachement
        return r
    }
    func colorAttachement(_ index: Int = 0,
                          texture: MTLTextureContainer? = nil,
                          loadAction: MTLLoadAction? = nil,
                          storeAction: MTLStoreAction? = nil,
                          mtlClearColor: MTLClearColor? = nil) -> Self{
        var _loadAction: Binding<MTLLoadAction>? = nil
        var _storeAction: Binding<MTLStoreAction>? = nil
        var _clearColor: Binding<MTLClearColor>? = nil
        if let loadAction = loadAction {
            _loadAction = Binding<MTLLoadAction>.constant(loadAction)
        }
        if let storeAction = storeAction {
            _storeAction = Binding<MTLStoreAction>.constant(storeAction)
        }
        if let clearColor = mtlClearColor {
            _clearColor = Binding<MTLClearColor>.constant(clearColor)
        }
        return colorAttachement(index,
                                texture: texture,
                                loadAction: _loadAction,
                                storeAction: _storeAction,
                                mtlClearColor: _clearColor)
    }
    func colorAttachement(_ index: Int = 0,
                          texture: MTLTextureContainer? = nil,
                          loadAction: MTLLoadAction? = nil,
                          storeAction: MTLStoreAction? = nil,
                          clearColor: Color? = nil) -> Self{
        var _clearColor: MTLClearColor? = nil
        if let color = clearColor{
            if let cgC = UIColor(color).cgColor.components{
                _clearColor = MTLClearColor(red:   cgC[0],
                                            green: cgC[1],
                                            blue:  cgC[2],
                                            alpha: cgC[3])
            }else{
                print("Could not get color components for color: ", color)
            }
        }
        return colorAttachement(index,
                                texture: texture,
                                loadAction: loadAction,
                                storeAction: storeAction,
                                mtlClearColor: _clearColor)
    }
    func colorAttachements(_ attachments: [Int: ColorAttachment]) -> Self{
        var r = self
        r.passColorAttachments = attachments
        return r
    }
}
