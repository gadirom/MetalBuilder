import MetalKit
import SwiftUI

public struct RenderableData{
    var passColorAttachments: [Int: ColorAttachment]
    var depthStencilDescriptor: MTLDepthStencilDescriptor?
    var passStencilAttachment: StencilAttachment?
    var stencilReferenceValue: UInt32?
    var pipelineColorAttachment: MTLRenderPipelineColorAttachmentDescriptor?
}
