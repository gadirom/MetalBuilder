
import MetalKit
import SwiftUI

/// The component for copying textures.
///
/// Use this component to copy memory between textures on GPU.
/// Configure source, destination, sliceCount and size with modifiers.
/// If no destination is set tries to copy to drawable.
public struct BlitArrayOfTextures: MetalBuilderComponent{
    
    var inArray: ArrayOfTexturesContainer?
    var outArray: ArrayOfTexturesContainer?
    
    var inRange: MetalBinding<ClosedRange<Int>> = .constant(0...0)
    var outRange: MetalBinding<ClosedRange<Int>>?
    
    var outContainer: MTLTextureContainer?
    
    var sourceSlice: MetalBinding<Int> = .constant(0)
    var destinationSlice: MetalBinding<Int> = .constant(0)
    var copyToSlices: Bool = false
    
    var sliceCount: MetalBinding<Int> = MetalBinding<Int>.constant(1)
    
    var size: MetalBinding<MTLSize>?
    
    let label: String
    
    public init(_ label: String=""){
        self.label = label
    }
}

// modifiers for BlitTexture.
public extension BlitArrayOfTextures{
    func source(_ container: ArrayOfTexturesContainer,
                range: MetalBinding<ClosedRange<Int>>,
                slice: MetalBinding<Int>=MetalBinding<Int>.constant(0))->BlitArrayOfTextures{
        var b = self
        b.sourceSlice = slice
        b.inArray = container
        b.inRange = range
        return b
    }
    func destination(_ container: ArrayOfTexturesContainer,
                     range: MetalBinding<ClosedRange<Int>>?=nil,
                     slice: MetalBinding<Int>=MetalBinding<Int>.constant(0))->BlitArrayOfTextures{
        var b = self
        b.destinationSlice = slice
        b.outArray = container
        b.outRange = range
        return b
    }
    //copy to slices will copy from textures id to slices of array texture
    func destination(_ singleTexture: MTLTextureContainer,
                     slice: MetalBinding<Int>=MetalBinding<Int>.constant(0), copyToSlices: Bool = false)->BlitArrayOfTextures{
        var b = self
        b.destinationSlice = slice
        b.outContainer = singleTexture
        b.copyToSlices = copyToSlices
        return b
    }
    func sliceCount(_ binding: MetalBinding<Int>)->BlitArrayOfTextures{
        var b = self
        b.sliceCount = binding
        return b
    }
    /*func size(size: Binding<MTLSize>)->BlitTexture{
        var b = self
        b.size = size
        return b
    }*/
}
