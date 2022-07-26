
import MetalKit
import SwiftUI

public enum MetalBuilderComputeError: Error{
    case noGridFit(String),
         gridFitTextureIsNil(String),
         gridFitNoBuffer(String),
         
         noComputeEncoder(String),
         textureIsNil(String)
}

//Compute Pass
final class ComputePass: MetalPass{
    var component: Compute
    
    var computePiplineState: MTLComputePipelineState!
    var threadsPerThreadGroup: MTLSize!
    var threadGroupsPerGrid: MTLSize!
    
    init(_ component: Compute){
        self.component = component
    }
    func setup(device: MTLDevice, library: MTLLibrary) throws{
        try component.setup()
        let function = library.makeFunction(name: component.kernel)
        computePiplineState =
            try device.makeComputePipelineState(function: function!)
    }
    // depth is ignored!!
    func setGrid(_ drawable: CAMetalDrawable?) throws{
        var size: MTLSize
        switch component.gridFit!{
        case .fitTexture(let container):
            guard let texture = container.texture
            else{
                throw MetalBuilderComputeError
                    .gridFitTextureIsNil("fitTextrure for threads dispatching for the kernel: "+component.kernel+" is nil!")
            }
            size = MTLSize(width: texture.width, height: texture.height, depth: 1)
        case .size(let s): size = s.wrappedValue
        case .drawable: size = MTLSize(width: drawable!.texture.width, height: drawable!.texture.height, depth: 1)
        case .buffer(let index):
            guard let buf = component.buffers.first(where: { $0.index == index })
            else{
                throw MetalBuilderComputeError
                    .gridFitNoBuffer("buffer \(index) for threads dispatching for the kernel: '"+component.kernel+"' is not found!")
            }
            size = MTLSize(width: buf.count, height: 1, depth: 1)
        }
        let w = computePiplineState.threadExecutionWidth
        let h = min(size.height, computePiplineState.maxTotalThreadsPerThreadgroup / w)
        
        threadsPerThreadGroup = MTLSize(width: w, height: h, depth: 1)
        threadGroupsPerGrid = MTLSize(
            width: Int(ceil(Double(size.width)/Double(w))),
            height: Int(ceil(Double(size.height)/Double(h))), depth: 1)
    }
    func encode(_ commandBuffer: MTLCommandBuffer,_ drawable: CAMetalDrawable? = nil) throws{
        guard let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
        else{
            throw MetalBuilderComputeError
                .noComputeEncoder("Wasn't able to create computeEncoder for the kernel: "+component.kernel)
        }
        //Set Buffers
        computeCommandEncoder.setComputePipelineState(computePiplineState)
        for buffer in component.buffers{
            computeCommandEncoder.setBuffer(buffer.mtlBuffer, offset: buffer.offset, index: buffer.index)
        }
        //Set Bytes
        for bytes in component.bytes{
            bytes.encode{ pointer, length, index in
                computeCommandEncoder.setBytes(pointer, length: length, index: index)
            }
        }
        //Set Textures
        for tex in component.textures{
            guard let texture = tex.container.texture
            else{
                throw MetalBuilderComputeError
                    .gridFitTextureIsNil("Texture \(tex.index) for the kernel  '"+component.kernel+"' is nil!")
            }
            computeCommandEncoder.setTexture(texture, index: tex.index)
        }
        if let index = component.drawableTextureIndex{
            computeCommandEncoder.setTexture(drawable?.texture, index: index)
        }
        //Set threads configuration
        try setGrid(drawable)
        //Dispatch
        computeCommandEncoder.dispatchThreadgroups(threadGroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        computeCommandEncoder.endEncoding()
    }
}
