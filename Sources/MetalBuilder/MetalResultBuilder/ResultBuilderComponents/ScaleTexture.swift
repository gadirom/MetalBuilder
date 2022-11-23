
import MetalKit
import SwiftUI

public enum ScaleMethod{
        //case nearestNeighbor //- not implemented!
        case lanczos
        case bilinear
}

public enum ScaleType{
        case fit
        case fill
        case `default`
}

/// The component to scale textures.
///
/// - Parameters:
///   - type: Fit or fill with respect to destination size.
///   - method: lanczos or biliniar.
///
/// A wrapper for the MPSImageScale shader.
/// Pass textures in `.source` and `.destination` modifiers.
/// If destination is ommited the drawable texture will be used as a destination.
public struct ScaleTexture: MetalBuilderComponent{
    
    var inTexture: MTLTextureContainer?
    var outTexture: MTLTextureContainer?
    
    var inplaceTexture: MTLTextureContainer?
    
    var zoom: Binding<Double> = Binding<Double>.constant(1)
    var offset: Binding<CGSize> = Binding<CGSize>.constant(CGSize(width: 0, height: 0))
    var destinationSize: Binding<simd_uint2>?
    
    var type: ScaleType
    var method: ScaleMethod

    public init(type: ScaleType, method: ScaleMethod){
        self.type = type
        self.method = method
    }
}

// chaining functions
public extension ScaleTexture{
//    func inplace(_ container: MTLTextureContainer, destinationSize: Binding<simd_uint2>? = nil)->ScaleTexture{
//        var s = self
//        s.destinationSize = destinationSize
//        s.inplaceTexture = container
//        return s
//    }
//    func inplace(_ container: MTLTextureContainer, destinationSize: simd_uint2)->ScaleTexture{
//        let s = self
//        return s.inplace(container, destinationSize: Binding<simd_uint2>.constant(destinationSize))
//    }
    func source(_ container: MTLTextureContainer)->ScaleTexture{
        var s = self
        s.inTexture = container
        return s
    }
    func destination(_ container: MTLTextureContainer)->ScaleTexture{
        var s = self
        s.outTexture = container
        return s
    }
    func zoom(z: Binding<Double>)->ScaleTexture{
        var s = self
        s.zoom = z
        return s
    }
    func zoom(z: Double)->ScaleTexture{
        var s = self
        s.zoom = Binding<Double>.constant(z)
        return s
    }
    func offset(_ offset: Binding<CGSize>)->ScaleTexture{
        var s = self
        s.offset = offset
        return s
    }
    func offset(_ offset: CGSize)->ScaleTexture{
        let s = self
        return s.offset(Binding<CGSize>.constant(offset))
    }
}
