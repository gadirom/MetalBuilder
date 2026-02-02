
import SwiftUI
import MetalKit

@propertyWrapper
public final class ArrayOfTextures{
    public var wrappedValue: ArrayOfTexturesContainer
    
    public var projectedValue: ArrayOfTextures{
        self
    }
    
    public init(type: MTLTextureType, maxCount: Int,
                label: String?=nil,
                useHeap: Bool = true,
                groups: [(String, TextureDescriptor)]?=nil,
                addToArgBuffers:  [(ArgumentBuffer, MetalTextureArgument)]?=nil){
        wrappedValue = ArrayOfTexturesContainer(type: type,
                                                maxCount: maxCount,
                                                label: label,
                                                useHeap: useHeap,
                                                groups: groups,
                                                addToArgBuffers: addToArgBuffers)
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

public final class ArrayOfTexturesContainer: ResourceManager.Entry{
    public init(type: MTLTextureType, maxCount: Int, label: String? = nil,
                useHeap: Bool,
                groups: [(String, TextureDescriptor)]?=nil,
                addToArgBuffers:  [(ArgumentBuffer, MetalTextureArgument)]?=nil){
        self.type = type
        self.maxCount = maxCount
        self.label = label
        self.heap = MTLHeapContainer()
        self.useHeap = useHeap
        
        ResourceManager.registerArrayOfTextures(
            groups: groups,
            aot: self,
            argumentBuffers: addToArgBuffers
        )
    }
    
    internal var type: MTLTextureType
    var maxCount: Int
    public var label: String?
    
    public var mtlTextures: [MTLTexture]{
        self.textures.map{ $0.texture! }
    }
    
    public var heap: MTLHeapContainer?
    public var useHeap: Bool
    
    //var _texturesCount: Int = 0
    
    //var descriptor: MTLTextureDescriptor?
    
    public private(set) var textures: [MTLTextureContainer] = []// hold textures from the array
    
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
    
    func clearAll(){
        self.heap?.heap = nil
        self.textures = []
    }
    
    func addMTLTexturesWithoutCopying(textures inTextures: [MTLTexture?]) throws{
        let containers = inTextures.map{ t in
            let container = MTLTextureContainer()
            container.texture = t
            return container
        }
        try addTextures(containers: containers)
    }
    
    func create(textures inTextures: [MTLTexture?], 
                usage: MTLTextureUsage = [.shaderRead, .shaderWrite],
                device: MTLDevice, commandBuffer: MTLCommandBuffer,
                hazardTracking: MTLHazardTrackingMode,
                heapStorageMode: MTLStorageMode? = nil) throws{
        
        guard useHeap
        else{
            try addMTLTexturesWithoutCopying(textures: inTextures)
            return
        }
        
        let descriptors: [MTLTextureDescriptor?] = inTextures.map {
            if let t = $0{
                let desc = newDescriptorFromTexture(texture: t,
                                                    storageMode: heapStorageMode)
                desc.usage = usage
                return desc
            }else{
                return nil
            }
        }

        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        
        try create(descriptors: descriptors, device: device,
                   hazardTracking: hazardTracking,
                   heapStorageMode: heapStorageMode)
        
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
                hazardTracking: MTLHazardTrackingMode,
                heapStorageMode: MTLStorageMode? = nil) throws{
        
        
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
                   hazardTracking: hazardTracking,
                   heapStorageMode: heapStorageMode)
    }
    func create(descriptors: [MTLTextureDescriptor?],
                device: MTLDevice,
                hazardTracking: MTLHazardTrackingMode,
                heapStorageMode: MTLStorageMode? = nil) throws{
        guard descriptors.count<=maxCount else {
            throw ArrayOfTexturesContainerError
                .numberOfTexturesExceedMaxNum(label)
        }
        guard let heap
        else {
            throw ArrayOfTexturesContainerError
                .noHeap(label)
        }
        if useHeap{
            try heap.create(device: device, descriptors: descriptors,
                            hazardTracking: hazardTracking,
                            storageMode: heapStorageMode)
        }
        self.textures = []
        for desc in descriptors {
            try self.createTexture(descriptor: desc, device: device)
        }
    }
    //without check for heap!!
    //should run from other function after heap creation
    private func createTexture(descriptor: MTLTextureDescriptor?,
                               device: MTLDevice) throws{
        let container = MTLTextureContainer()
        
        container.argBufferInfo = self.argBufferInfo.withArrayIndex(textures.count)
                
        container.label = "\(self.label ?? "unlabeledArrayOfTextures") \(self.textures.count)"
        if let descriptor{
            guard let texture = useHeap ?
                    heap!.heap!.makeTexture(descriptor: descriptor) :
                         device.makeTexture(descriptor: descriptor)
            else{
                throw ArrayOfTexturesContainerError
                    .textureWasNotCreated(textures.count, label)
            }
            texture.label = container.label
            container.texture = texture
        }
        textures.append(container)
    }
    
    
    func addTextures(containers: [MTLTextureContainer]) {
        textures = []
        for c in containers{
            try addTexture(container: c)
        }
        //useHeap = false
    }
    
    private func addTexture(container: MTLTextureContainer){
        
        container.argBufferInfo = self.argBufferInfo.withArrayIndex(textures.count)
                
        container.label = "\(self.label ?? "unlabeledArrayOfTextures") \(self.textures.count)"
        //container.texture!.label = container.label
        
        textures.append(container)
    }
}

extension ArrayOfTexturesContainer: MTLResourceContainer{
    var mtlResources: [MTLResource]{
        useHeap ? [] : mtlTextures
    }
    func updateResource(argBuffer: ArgumentBuffer, id: Int, offset: Int){
        //no need to update resources for array of textures
        //argBuffer.encoder!.setTexture(self.texture, index: id)
        //print("updated texture resource [\(id)] in \(argBuffer.name)")
    }
}

func newDescriptorFromTexture(texture: MTLTexture,
                              storageMode: MTLStorageMode?) -> MTLTextureDescriptor{
        let descriptor = MTLTextureDescriptor()

        descriptor.textureType      = texture.textureType
        descriptor.pixelFormat      = texture.pixelFormat
        descriptor.width            = texture.width
        descriptor.height           = texture.height
        descriptor.depth            = texture.depth
        descriptor.mipmapLevelCount = texture.mipmapLevelCount
        descriptor.arrayLength      = texture.arrayLength
        descriptor.sampleCount      = texture.sampleCount
    
        descriptor.storageMode      = storageMode ?? texture.storageMode // .private

        return descriptor
}
