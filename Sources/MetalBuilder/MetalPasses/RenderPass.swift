
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
        if let depthStencilState = self.component.renderableData.depthStencilState{
            depthStencilState.create(device: renderInfo.device)
        }
        if let depthPixelFormat = renderInfo.depthPixelFormat{
            renderPipelineDescriptor.depthAttachmentPixelFormat = depthPixelFormat
        }
        if let stencilPixelFormat = renderInfo.stencilPixelFormat{
            renderPipelineDescriptor.stencilAttachmentPixelFormat = stencilPixelFormat
        }
        //Override global stencil pixel format with the one from stencil attachment texture
        if let pixelFormat = component.renderableData.passStencilAttachment?.texture?.descriptor.pixelFormat{
            if case let .fixed(stencilPixelFormat) = pixelFormat{
                renderPipelineDescriptor.stencilAttachmentPixelFormat = stencilPixelFormat
            }
        }
        
        //Pipeline Color Attachment
        if let pipelineColorAttachment = component.renderableData.pipelineColorAttachment{
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
    
    func makeEncoder(passInfo: MetalPassInfo) throws -> MTLRenderCommandEncoder{
        let commandBuffer = passInfo.getCommandBuffer()
        guard let createdRenderPassEncoder = commandBuffer.makeRenderCommandEncoder(renderableData: component.renderableData,
                                                                                    passInfo: passInfo)
        else{
            throw MetalBuilderRenderError
                .noRenderEncoder("Wasn't able to create renderEncoder for the vertex shader: '"+component.vertexFunc+"'!")
        }
        return createdRenderPassEncoder
    }
    
    func encode(passInfo: MetalPassInfo) throws {
        
        let encoderIsExternal: Bool
        let renderPassEncoder: MTLRenderCommandEncoder
    
        // render encoder external (passed in RenderableData) or internal
        if let externalEncoder = component.renderableData.passRenderEncoder{
            encoderIsExternal = true
            if let encoder = externalEncoder.encoder{
                renderPassEncoder = encoder
            }else{
                renderPassEncoder = try makeEncoder(passInfo: passInfo)
                externalEncoder.encoder = renderPassEncoder
            }
        }else{
            encoderIsExternal = false
            renderPassEncoder = try makeEncoder(passInfo: passInfo)
        }
        
        renderPassEncoder.configure(renderableData: component.renderableData, passInfo: passInfo)
        
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
            if let instanceCount = component.instanceCount{
                renderPassEncoder.drawIndexedPrimitives(type: component.type,
                                                        indexCount: component.indexCount.wrappedValue,
                                                        indexType: indexType,
                                                        indexBuffer: component.indexBuf!.mtlBuffer!,
                                                        indexBufferOffset: component.indexBufferOffset,
                                                        instanceCount: instanceCount.wrappedValue)
            }else{
                renderPassEncoder.drawIndexedPrimitives(type: component.type,
                                                        indexCount: component.indexCount.wrappedValue,
                                                        indexType: indexType,
                                                        indexBuffer: component.indexBuf!.mtlBuffer!,
                                                        indexBufferOffset: component.indexBufferOffset)
            }
        }else{
            if let instanceCount = component.instanceCount{
                renderPassEncoder.drawPrimitives(type: component.type,
                                                 vertexStart: component.vertexOffset,
                                                 vertexCount: component.vertexCount,
                                                 instanceCount: instanceCount.wrappedValue)
            }else{
                renderPassEncoder.drawPrimitives(type: component.type,
                                                 vertexStart: component.vertexOffset,
                                                 vertexCount: component.vertexCount)
            }
        }
        
        if !encoderIsExternal || component.renderableData.lastPass{
            renderPassEncoder.endEncoding()
            component.renderableData.passRenderEncoder?.encoder = nil
        }
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


