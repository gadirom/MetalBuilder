
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
            
            for argBuf in component.argumentsContainer.addedArgumentBuffers{
                try argBuf.0.create(device: renderInfo.device,
                                    mtlFunction: function,
                                    index: argBuf.1)
            }
            
        }
        
        //Additional pipeline setup logic
        if let additionalPiplineSetupClosure = component.additionalPiplineSetupClosure?.wrappedValue{
            additionalPiplineSetupClosure(computePiplineState, libraryContainer!.library!)
        }
        
        libraryContainer = nil
    }
    func setGrid(_ drawable: CAMetalDrawable?) throws -> MTLSize{
        var size: MTLSize
        var gridScale: MBGridScale = (1,1,1)
        switch component.gridFit!{
        case .fitTexture(let container, _, let gScale):
            guard let texture = container.texture
            else{
                throw MetalBuilderComputeError
                    .gridFitTextureIsNil("fitTextrure for threads dispatching for the kernel: "+component.kernel+" is nil!")
            }
            size = MTLSize(width: texture.width, height: texture.height, depth: texture.depth)
            gridScale = gScale
        case .size3D(let s):
            size = s.wrappedValue
        case .size2D(let bs):
            let s = bs.wrappedValue
            size = MTLSize(width: s.0, height: s.1, depth: 1)
        case .size1D(let s):
            size = MTLSize(width: s.wrappedValue, height: 1, depth: 1)
        case .drawable: size = MTLSize(width: drawable!.texture.width, height: drawable!.texture.height, depth: 1)
        case .fitBuffer(let buf, _, let gScale):
            guard let count = buf.count
            else{
                throw MetalBuilderComputeError
                    .gridFitNoBuffer("buffer \(String(describing: buf.metalName)) for threads dispatching for the kernel: '"+component.kernel+"' has no count!")
            }
            size = MTLSize(width: count, height: 1, depth: 1)
            gridScale = gScale
       
        }
        
        size.scale(gridScale)
        
        return size
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
        for argBuf in component.argumentsContainer.addedArgumentBuffers{
            argBuf.0.setEncoder()
        }
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
        
        //Use Resources
        for resourceUsage in component.argumentsContainer.resourcesUsages.allResourcesUsages{
            computeCommandEncoder.useResource(resourceUsage.resource.mtlResource,
                                              usage: resourceUsage.usage)
        }
        
        if let additionalEncodeClosure = component.additionalEncodeClosure?.wrappedValue{
            additionalEncodeClosure(computeCommandEncoder)
        }
        
        let size = try setGrid(passInfo.drawable)
        //Dispatch
        dispatch(size: size, commandEncoder: computeCommandEncoder)
        
        computeCommandEncoder.endEncoding()
    }
}
