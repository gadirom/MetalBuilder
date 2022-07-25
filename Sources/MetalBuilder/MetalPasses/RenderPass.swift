
import MetalKit
import SwiftUI

public enum MetalBuilderRenderError: Error{
    case noRenderEncoder(String),
         textureIsNil(String)
}

//Render Pass
final class RenderPass: MetalPass{
    var component: Render
    
    var renderPiplineState: MTLRenderPipelineState!
    
    init(_ component: Render){
        self.component = component
    }
    func setup(device: MTLDevice, library: MTLLibrary) throws{
        try component.setup()
        let vertexFunction = library.makeFunction(name: component.vertexFunc)
        let fragmentFunction = library.makeFunction(name: component.fragmentFunc)
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        renderPiplineState =
            try device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func encode(_ commandBuffer: MTLCommandBuffer, _ drawable: CAMetalDrawable?) throws{
        let descriptor = MTLRenderPassDescriptor()
        for key in component.colorAttachments.keys{
            if let a = component.colorAttachments[key]?.descriptor{
                if a.texture == nil{
                    a.texture = drawable?.texture
                }
                descriptor.colorAttachments[0] = a
            }
        }
        guard let renderPassEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else{
            throw MetalBuilderRenderError
                .noRenderEncoder("Wasn't able to create renderEncoder for the vertex shader: "+component.vertexFunc)
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
        renderPassEncoder.drawPrimitives(type: component.type, vertexStart: component.vertexStart, vertexCount: component.vertexCount)
        renderPassEncoder.endEncoding()
    }
}
