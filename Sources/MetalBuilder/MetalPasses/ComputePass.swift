
import MetalKit
import SwiftUI

public enum MetalBuilderComputeError: Error{
    case noGridFit(String),
         gridFitTextureIsNil(String),
         gridFitTextureIsUnknown(String),
         gridFitNoBuffer(String),
         
         noComputeEncoder(String),
         textureIsNil(String)
}

extension MetalBuilderComputeError: LocalizedError{
    public var errorDescription: String?{
        String(describing: self)
    }
}

func encodeGIDCount(encoder: MTLComputeCommandEncoder,
                    size: MTLSize,
                    indexType: IndexType,
                    bufferIndex: Int,
                    dim: Int){
    
    func encodeSize<T>(bytes: SIMD3<T>){
        var bytes = bytes
        encoder.setBytes(&bytes, length: MemoryLayout<T>.stride*dim, index: bufferIndex)
    }
    
    switch indexType{
    case .uint:
        let bytes = SIMD3<UInt32>(x: UInt32(size.width),
                                  y: UInt32(size.height),
                                  z: UInt32(size.depth))
        encodeSize(bytes: bytes)
    case .ushort:
        let bytes = SIMD3<UInt16>(x: UInt16(size.width),
                                  y: UInt16(size.height),
                                  z: UInt16(size.depth))
        encodeSize(bytes: bytes)
    }
}

//Compute Pass
final class ComputePass: MetalPass{
    
    var libraryContainer: LibraryContainer?
    
    var component: Compute
    
    var computePiplineState: MTLComputePipelineState!
    
    var supportsFamily4: Bool! //for non-uniform threads dispatching
    
    var gidCountDim: Int!
    
    init(_ component: Compute, libraryContainer: LibraryContainer){
        self.component = component
        self.libraryContainer = libraryContainer
    }
    func setup(renderInfo: GlobalRenderInfo) throws{
        
        self.gidCountDim = try component.gridFit!.threadPositionInGridDim
        
        supportsFamily4 = renderInfo.supportsFamily4
        
        if let piplineSetupClosure = component.piplineSetupClosure?.wrappedValue{
            computePiplineState = piplineSetupClosure(renderInfo.device, libraryContainer!.library!)
        }else{
            let function = libraryContainer!.library!.makeFunction(name: component.kernel)!
            computePiplineState =
            try renderInfo.device.makeComputePipelineState(function: function)
            
            try component
                .argumentsContainer
                .createArgumentBuffers(device: renderInfo.device,
                                       mtlFunction: function)
            
        }
        
        //Additional pipeline setup logic
        if let additionalPiplineSetupClosure = component.additionalPiplineSetupClosure?.wrappedValue{
            additionalPiplineSetupClosure(computePiplineState, libraryContainer!.library!)
        }
        
        libraryContainer = nil
    }
    
    func dispatch(size: MTLSize, commandEncoder: MTLComputeCommandEncoder){
        
        encodeGIDCount(encoder: commandEncoder,
                       size: size,
                       indexType: component.indexType,
                       bufferIndex: component.argumentsContainer.buffersAndBytesContainer.indexCounter,
                       dim: gidCountDim)
        
        let w = computePiplineState.threadExecutionWidth
        let h = min(size.height, computePiplineState.maxTotalThreadsPerThreadgroup / w)
        
        //threads per threadgroup
        var threadsPerThreadgroup: MTLSize
        if let t = component.threadsPerThreadgroup{
            threadsPerThreadgroup = t.wrappedValue
        }else{
            threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
        }
        
        if supportsFamily4{
            commandEncoder.dispatchThreads(size,
                            threadsPerThreadgroup: threadsPerThreadgroup)
        }else{
            
            let threadgroupsPerGrid = MTLSize(
                width: Int(ceil(Double(size.width)/Double(w))),
                height: Int(ceil(Double(size.height)/Double(h))), depth: size.depth)
            
            commandEncoder.dispatchThreadgroups(threadgroupsPerGrid,
                                                threadsPerThreadgroup: threadsPerThreadgroup)
        }
    
    }
    func prerun(renderInfo: GlobalRenderInfo) throws {
        component.argumentsContainer.prerun()
    }
    func encode(passInfo: MetalPassInfo) throws {
        let commandBuffer = passInfo.getCommandBuffer()
        guard let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
        else{
            throw MetalBuilderComputeError
                .noComputeEncoder("Wasn't able to create computeEncoder for the kernel: "+component.kernel)
        }
        #if DEBUG
        computeCommandEncoder.label = component.kernel
        #endif
        
        //Use Resources
        for resourceUsage in component.argumentsContainer.resourcesUsages.allResourcesUsages{
            computeCommandEncoder.useResource(resourceUsage.resource.mtlResource,
                                              usage: resourceUsage.usage)
        }
        
        //Use Heaps
        computeCommandEncoder.useHeaps(component.argumentsContainer.resourcesUsages.allHeapsUsed.compactMap{ $0.heap })
        
        computeCommandEncoder.setComputePipelineState(computePiplineState)
        
        //Set Buffers
        for buffer in component.argumentsContainer.buffersAndBytesContainer.buffers{
            computeCommandEncoder.setBuffer(buffer.mtlBuffer,
                                            offset: buffer.offset.wrappedValue,
                                            index: buffer.index)
        }
        //Set Bytes
        for bytes in component.argumentsContainer.buffersAndBytesContainer.bytes{
            bytes.encode{ pointer, length, index in
                computeCommandEncoder.setBytes(pointer, length: length, index: index)
            }
        }
        //Set Textures
        for tex in component.argumentsContainer.texturesContainer.textures{
            guard let texture = tex.container.texture
            else{
                throw MetalBuilderComputeError
                    .gridFitTextureIsNil("Texture \(tex.index) for the kernel  '"+component.kernel+"' is nil!")
            }
            computeCommandEncoder.setTexture(texture, index: tex.index)
        }
        if let index = component.drawableTextureIndex{
            computeCommandEncoder.setTexture(passInfo.drawable?.texture, index: index)
        }
        
        if let additionalEncodeClosure = component.additionalEncodeClosure?.wrappedValue{
            additionalEncodeClosure(computeCommandEncoder)
        }
        
        let size = try component.gridFit!.gridSize(passInfo.drawable)
        //Dispatch
        dispatch(size: size, commandEncoder: computeCommandEncoder)
        
        computeCommandEncoder.endEncoding()
    }
}
