import MetalKit
import SwiftUI
import MetalPerformanceShaders

/// The component to run metal performance shaders.
///
/// Set source and destination textures with modifiers.
/// If no destination is set tries to encode in place.
public struct MPSUnary: MetalBuilderComponent{
    
    let initCode: (MTLDevice)->MPSUnaryImageKernel
    var inTexture: MTLTextureContainer?
    var outTexture: MTLTextureContainer?
    var outToDrawable = false
    var dict: [String: Binding<Float>] = [:]
    /// Initializes the component that runs a MPSUnaryImageKernel.
    /// - Parameter initCode: The code to initialize the MPSUnaryImageKernel.
    public init(_ initCode: @escaping (MTLDevice)->MPSUnaryImageKernel){
        self.initCode = initCode
    }
}

// chaining functions
public extension MPSUnary{
    func value(_ binding: Binding<Float>, for key: String)->MPSUnary{
        var m = self
        m.dict[key] = binding
        return m
    }
    func source(_ container: MTLTextureContainer)->MPSUnary{
        var m = self
        m.inTexture = container
        return m
    }
    func destination(_ container: MTLTextureContainer)->MPSUnary{
        var m = self
        m.outTexture = container
        return m
    }
    func toDrawable()->MPSUnary{
        var m = self
        m.outToDrawable = true
        return m
    }
}
