
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
    
    var depthState: MTLDepthStencilState?
    
    init(_ component: Render, libraryContainer: LibraryContainer){
        self.component = component
        self.libraryContainer = libraryContainer
    }
    func setup(device: MTLDevice) throws{
        try component.setup()
        let vertexFunction = libraryContainer!.library!.makeFunction(name: component.vertexFunc)
        let fragmentFunction = libraryContainer!.library!.makeFunction(name: component.fragmentFunc)
        libraryContainer = nil
        
        let descriptor = MTLRenderPipelineDescriptor()
        
        //depth routine
        let dephDescriptor = MTLDepthStencilDescriptor()
        dephDescriptor.depthCompareFunction = .lessEqual
        dephDescriptor.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: dephDescriptor)
        
        descriptor.depthAttachmentPixelFormat = .depth32Float
        //
        
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        renderPiplineState =
            try device.makeRenderPipelineState(descriptor: descriptor)
        
        if component.indexedPrimitives{
            if let buf = component.indexBuf{
                indexType = try getIndexType(buf.elementType)
                try buf.create(device: device)
            }else{
                throw MetalBuilderRenderError.badIndexBuffer("No index buffer was provided for '" + self.component.vertexFunc + "'!")
            }
        }
    }
    
    func encode(passInfo: MetalPassInfo) throws {
        let commandBuffer = passInfo.getCommandBuffer()
        let descriptor = passInfo.renderPassDescriptor
        
        for key in component.colorAttachments.keys{
            if let a = component.colorAttachments[key]?.descriptor{
                if a.texture == nil{
                    a.texture = passInfo.drawable?.texture
                }
                descriptor.colorAttachments[0] = a
            }
        }
        guard let renderPassEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else{
            throw MetalBuilderRenderError
                .noRenderEncoder("Wasn't able to create renderEncoder for the vertex shader: '"+component.vertexFunc+"'!")
        }
        
        //Viewport
        var viewport: MTLViewport
        if let v = component.viewport?.wrappedValue{
            viewport = v
        }else{
            viewport = MTLViewport(originX: 0.0, originY: 0.0, width: Double(descriptor.colorAttachments[0].texture!.width), height: Double(descriptor.colorAttachments[0].texture!.height), znear: 0.0, zfar: 1.0)
        }
        renderPassEncoder.setViewport(viewport)
        
        renderPassEncoder.setRenderPipelineState(renderPiplineState)
        
        //set depth state
        renderPassEncoder.setDepthStencilState(depthState)
        
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


