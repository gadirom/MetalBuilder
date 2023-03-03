
import MetalKit
import SwiftUI

public enum MetalBuilderRenderError: Error{
    case noRenderEncoder(String),
         textureIsNil(String),
         badIndexBuffer(String)
}

//Render Pass
final class RenderPass: MetalPass{
    
    var libraryContainer: LibraryContainer?
    
    var component: Render
    
    var renderPiplineState: MTLRenderPipelineState!
    
    var indexType: MTLIndexType = .uint16
    
    var depthStencilState: MTLDepthStencilState?
    let defaultStencilDescriptor = MTLRenderPassStencilAttachmentDescriptor()
    
    init(_ component: Render, libraryContainer: LibraryContainer){
        self.component = component
        self.libraryContainer = libraryContainer
    }
    func setup(renderInfo: GlobalRenderInfo) throws{
        try component.setup()
        let vertexFunction = libraryContainer!.library!.makeFunction(name: component.vertexFunc)
        let fragmentFunction = libraryContainer!.library!.makeFunction(name: component.fragmentFunc)
        libraryContainer = nil
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        
        //depth and stencil routine
        if let depthDescriptor = self.component.depthStencilDescriptor{
            depthStencilState = renderInfo.device.makeDepthStencilState(descriptor: depthDescriptor)
        }
        if let depthPixelFormat = renderInfo.depthPixelFormat{
            renderPipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
        }
        if let stencilPixelFormat = renderInfo.stencilPixelFormat{
            renderPipelineDescriptor.stencilAttachmentPixelFormat = stencilPixelFormat
        }
        //Override global stencil pixel format with the one from stencil attachment texture
        if let pixelFormat = component.passStencilAttachment?.texture?.descriptor.pixelFormat{
            if case let .fixed(stencilPixelFormat) = pixelFormat{
                renderPipelineDescriptor.stencilAttachmentPixelFormat = stencilPixelFormat
            }
        }
        
        //Pipeline Color Attachment
        if let pipelineColorAttachment = component.pipelineColorAttachment{
            renderPipelineDescriptor.colorAttachments[0] = pipelineColorAttachment
        }
        if renderPipelineDescriptor.colorAttachments[0].pixelFormat.rawValue == 0{
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = renderInfo.pixelFormat
        }
        
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPiplineState =
            try renderInfo.device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        
        if component.indexedPrimitives{
            if let buf = component.indexBuf{
                indexType = try getIndexType(buf.elementType)
                try buf.create(device: renderInfo.device)
            }else{
                throw MetalBuilderRenderError.badIndexBuffer("No index buffer was provided for '" + self.component.vertexFunc + "'!")
            }
        }
    }
    
    func encode(passInfo: MetalPassInfo) throws {
        let commandBuffer = passInfo.getCommandBuffer()
        let renderPassDescriptor = passInfo.renderPassDescriptor
        
        //Configuring Render Pass Descriptor
        
        //color attachments
        for key in component.passColorAttachments.keys{
            if let a = component.passColorAttachments[key]?.descriptor{
                if a.texture == nil{
                    a.texture = passInfo.drawable?.texture
                }
                renderPassDescriptor.colorAttachments[key] = a
            }
        }
        
        //stencil attachment
        if let passStencilAttachment = component.passStencilAttachment{
            renderPassDescriptor.stencilAttachment = passStencilAttachment.descriptor
        }else{
            renderPassDescriptor.stencilAttachment = defaultStencilDescriptor
        }
        
        //Configuring Render Pass Encoder
        
        guard let renderPassEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else{
            throw MetalBuilderRenderError
                .noRenderEncoder("Wasn't able to create renderEncoder for the vertex shader: '"+component.vertexFunc+"'!")
        }
        
        //Viewport
        var viewport: MTLViewport
        if let v = component.viewport?.wrappedValue{
            viewport = v
        }else{
            viewport = MTLViewport(originX: 0.0, originY: 0.0, width: Double(renderPassDescriptor.colorAttachments[0].texture!.width), height: Double(renderPassDescriptor.colorAttachments[0].texture!.height), znear: 0.0, zfar: 1.0)
        }
        renderPassEncoder.setViewport(viewport)
        
        //set depth and stencil state
        if let depthStencilState = depthStencilState {
            renderPassEncoder.setDepthStencilState(depthStencilState)
        }
        
        //set stencil reference value
        if let stencilReferenceValue = component.stencilReferenceValue{
            renderPassEncoder.setStencilReferenceValue(stencilReferenceValue)
        }
        
        renderPassEncoder.setRenderPipelineState(renderPiplineState)
        
        //Set Buffers
        for buffer in component.vertexBufs{
            renderPassEncoder.setVertexBuffer(buffer.mtlBuffer, offset: buffer.offset, index: buffer.index)
        }
        for buffer in component.fragBufs{
            renderPassEncoder.setFragmentBuffer(buffer.mtlBuffer, offset: buffer.offset, index: buffer.index)
        }
        //Set Bytes
        for bytes in component.vertexBytes{
            bytes.encode{ pointer, length, index in
                renderPassEncoder.setVertexBytes(pointer, length: length, index: index)
            }
        }
        for bytes in component.fragBytes{
            bytes.encode{ pointer, length, index in
                renderPassEncoder.setFragmentBytes(pointer, length: length, index: index)
            }
        }
        //Set Textures
        for tex in component.vertexTextures{
            guard let texture = tex.container.texture
            else{
                throw MetalBuilderRenderError
                    .textureIsNil("Texture \(tex.index) for the vertex shader  '"+component.vertexFunc+"' is nil!")
            }
            renderPassEncoder.setVertexTexture(texture, index: tex.index)
        }
        for tex in component.fragTextures{
            guard let texture = tex.container.texture
            else{
                throw MetalBuilderRenderError
                    .textureIsNil("Texture \(tex.index) for the fragment shader  '"+component.fragmentFunc+"' is nil!")
            }
            renderPassEncoder.setFragmentTexture(texture, index: tex.index)
        }
        
        if component.indexedPrimitives{
            renderPassEncoder.drawIndexedPrimitives(type: component.type,
                                                    indexCount: component.indexCount.wrappedValue,
                                                    indexType: indexType,
                                                    indexBuffer: component.indexBuf!.mtlBuffer!,
                                                    indexBufferOffset: component.indexBufferOffset)
        }else{
            renderPassEncoder.drawPrimitives(type: component.type, vertexStart: component.vertexOffset, vertexCount: component.vertexCount)
        }
        
        
        renderPassEncoder.endEncoding()
    }
    func getIndexType(_ indexType: Any.Type) throws ->MTLIndexType{
        
        if indexType == UInt32.self{
            return .uint32
        }
        if indexType == UInt16.self{
            return .uint16
        }
        
        throw MetalBuilderRenderError.badIndexBuffer("Elements of the index buffer for '" + self.component.vertexFunc + "' is of wrong type. Should be UInt32 or UInt16!")

    }
}


