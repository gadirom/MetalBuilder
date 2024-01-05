
import SwiftUI
import MetalKit

@propertyWrapper
public final class ArrayOfTextures{
    public var wrappedValue: ArrayOfTexturesContainer
    
    public var projectedValue: ArrayOfTextures{
        self
    }
    
    public init(type: MTLTextureType, maxCount: Int, label: String?=nil){
        wrappedValue = ArrayOfTexturesContainer(type: type,
                                                maxCount: maxCount,
                                                label: label)
    }
    
//    public init(fromImages: [ImageForTexture]? = nil){
//        self.wrappedValue = MTLTextureArrayContainer
//            .loadImages(descriptor, label: label, fromImage: fromImage)
//    }
}

public enum ArrayOfTexturesContainerError: Error{
    case numberOfTexturesExceedMaxNum(String?),
    noHeap(String?),
    textureWasNotCreated(Int, String?)
}

extension ArrayOfTexturesContainerError: LocalizedError{
    public var errorDescription: String?{
        switch self {
        case .numberOfTexturesExceedMaxNum(let label):
            "Tried to create more textures to ArrayOfTextures \(label ?? "") than maximum number of textures for this array! (Resereve more textures or ask to create less textures)"
        case .noHeap(let label):
            "No heap for ArrayOfTextures \(label ?? "")!"
        case .textureWasNotCreated(let textureId, let label):
            "Texture \(textureId) in ArrayOfTextures \(label ?? "") was not created!"
        }
    }
}

public final class ArrayOfTexturesContainer{
    internal init(type: MTLTextureType, maxCount: Int, label: String? = nil){
        self.type = type
        self.maxCount = maxCount
        self.label = label
        self.heap = MTLHeapContainer()
    }
    
    internal var type: MTLTextureType
    var maxCount: Int
    public var label: String?
    
    var heap: MTLHeapContainer?
    
    var _texturesCount: Int = 0
    
    var descriptor: MTLTextureDescriptor?
    
    var textures: [MTLTextureContainer] = []// hold textures from the array
    
    public subscript(id: Int) -> MTLTextureContainer?{
        textures[id]
    }
    
    internal var argBufferInfo = ArgBufferInfo()
    internal var dataType: MTLDataType = .array
    
    
//    public func load(textures: [TextureSize]) throws{
//        
//    }
    
}


public extension ArrayOfTexturesContainer{
    
    func create(textures inTextures: [MTLTexture?], 
                usage: MTLTextureUsage = [.shaderRead, .shaderWrite],
                device: MTLDevice, commandBuffer: MTLCommandBuffer,
                hazardTracking: MTLHazardTrackingMode) throws{
        let descriptors: [MTLTextureDescriptor?] = inTextures.map {
            if let t = $0{
                let desc = newDescriptorFromTexture(texture: t)
                desc.usage = usage
                return desc
            }else{
                return nil
            }
        }

        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        
        try create(descriptors: descriptors, device: device,
                   hazardTracking: hazardTracking)
        
        for (id, inTexture) in inTextures.enumerated() {
            
            if let inTexture{
                
                blitEncoder?.copy(from: inTexture,
                                  sourceSlice: 0,
                                  sourceLevel: 0,
                                  to: textures[id].texture!,
                                  destinationSlice: 0,
                                  destinationLevel: 0,
                                  sliceCount: inTexture.mipmapLevelCount,
                                  levelCount: inTexture.arrayLength)
            }
        }
        blitEncoder?.endEncoding()
    }
    func create(sizes: [MTLSize],
                pixelFormat: MTLPixelFormat,
                usage: MTLTextureUsage,
                device: MTLDevice,
                hazardTracking: MTLHazardTrackingMode) throws{
        
        
        let descriptors: [MTLTextureDescriptor?] = sizes.map {
            
            if $0.width==0 || $0.height==0 || $0.depth==0{
                return nil
            }
            
            let descriptor = MTLTextureDescriptor()

            descriptor.textureType      = self.type
            descriptor.pixelFormat      = pixelFormat
            descriptor.width            = $0.width
            descriptor.height           = $0.height
            descriptor.depth            = $0.depth
            descriptor.usage            = usage
            //descriptor.mipmapLevelCount = texture.mipmapLevelCount
            //descriptor.arrayLength      = 1
            //descriptor.sampleCount      = texture.sampleCount
            //descriptor.storageMode      = storageMode

            return descriptor
        }
        
        try create(descriptors: descriptors, device: device,
                   hazardTracking: hazardTracking)
    }
    func create(descriptors: [MTLTextureDescriptor?],
                device: MTLDevice,
                hazardTracking: MTLHazardTrackingMode) throws{
        guard descriptors.count<=maxCount else {
            throw ArrayOfTexturesContainerError
                .numberOfTexturesExceedMaxNum(label)
        }
        guard let heap
        else {
            throw ArrayOfTexturesContainerError
                .noHeap(label)
        }
        try heap.create(device: device, descriptors: descriptors,
                        hazardTracking: hazardTracking)
        self.textures = []
        for desc in descriptors {
            try self.createTexture(descriptor: desc)
        }
    }
    //without check for heap!!
    //should run from other function after heap creation
    private func createTexture(descriptor: MTLTextureDescriptor?) throws{
        let container = MTLTextureContainer()
        
        container.argBufferInfo = self.argBufferInfo.withArrayIndex(textures.count)
                
        container.label = "\(self.label ?? "unlabeledArrayOfTextures") \(self.textures.count)"
        if let descriptor{
            guard let texture = heap!.heap!.makeTexture(descriptor: descriptor)
            else{
                throw ArrayOfTexturesContainerError
                    .textureWasNotCreated(textures.count, label)
            }
            texture.label = container.label
            container.texture = texture
        }
        textures.append(container)
    }
}

func newDescriptorFromTexture(texture: MTLTexture) -> MTLTextureDescriptor{
        let descriptor = MTLTextureDescriptor()

        descriptor.textureType      = texture.textureType
        descriptor.pixelFormat      = texture.pixelFormat
        descriptor.width            = texture.width
        descriptor.height           = texture.height
        descriptor.depth            = texture.depth
        descriptor.mipmapLevelCount = texture.mipmapLevelCount
        descriptor.arrayLength      = texture.arrayLength
        descriptor.sampleCount      = texture.sampleCount
        //descriptor.storageMode      = storageMode

        return descriptor
}
