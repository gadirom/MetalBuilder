
import SwiftUI
import MetalKit
/*
@propertyWrapper
public final class MetalHeap{
    public var wrappedValue: MTLHeapContainer
    
    public var projectedValue: MetalHeap{
        self
    }
    
    public init(wrappedValue: MTLHeapContainer){
        self.wrappedValue = wrappedValue
    }
    
    public init(label: String?=nil){
        let desc = MTLHeapDescriptor()
        //desc.size =
        desc.storageMode = .private
        //desc.cpuCacheMode = .defaultCache
        //desc.sparsePageSize: MTLSparsePageSize
        desc.hazardTrackingMode = .tracked
        desc.type = .placement
        
        self.wrappedValue = MTLHeapContainer(descriptor: desc)
    }
}
*/
//enum MetalBuilderTextureError: Error {
//case textureNotCreated, noDescriptor, descriptorSizeContainsZero,
//    pixelFormatFromDrawable
//}

public final class MTLHeapContainer{
//    internal init(descriptor: MTLHeapDescriptor) {
//        self.descriptor = descriptor
//    }
    
    init() {
    }
    
    //public var descriptor: MTLHeapDescriptor
    public var heap: MTLHeap?
    public var label: String?
    
    /// Creates a resource heap to store textures
    func create(device: MTLDevice, descriptors: [MTLTextureDescriptor?]) throws{
        
        let heapDescriptor = MTLHeapDescriptor()
        heapDescriptor.storageMode = .private
        heapDescriptor.size =  0
        heapDescriptor.hazardTrackingMode = .tracked

        // Build a descriptor for each texture and calculate the size required to store all textures in the heap
        for i in 0..<descriptors.count{
            // Create a descriptor using the texture's properties
            guard let descriptor = descriptors[i]
            else { continue }
            
            descriptor.storageMode = heapDescriptor.storageMode
            // Determine the size required for the heap for the given descriptor
            var sizeAndAlign = device.heapTextureSizeAndAlign(descriptor: descriptor)

            // Align the size so that more resources will fit in the heap after this texture
            sizeAndAlign.size += (sizeAndAlign.size & (sizeAndAlign.align - 1)) + sizeAndAlign.align

            // Accumulate the size required to store this texture in the heap
            heapDescriptor.size += sizeAndAlign.size
        }
        // Create a heap large enough to store all resources
        heap = device.makeHeap(descriptor: heapDescriptor)
    }
    
}

extension MTLHeapContainer: Equatable{
    public static func == (lhs: MTLHeapContainer, rhs: MTLHeapContainer) -> Bool {
        lhs === rhs
    }
}
