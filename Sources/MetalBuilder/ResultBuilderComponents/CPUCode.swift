
import MetalKit
import SwiftUI

/// Draw Code Component
///
/// runs plain code in draw function
public struct CPUCode: MetalBuilderComponent{
    let code: (MTLDevice, MTLCommandBuffer, CAMetalDrawable?) -> ()
    
    public init(code: @escaping (MTLDevice, MTLCommandBuffer, CAMetalDrawable?) -> ()) {
        self.code = code
    }
}
