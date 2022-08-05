
import MetalKit
import SwiftUI

/// Draw Code Component
///
/// runs plain code in draw function
public struct ManualEncode: MetalBuilderComponent{
    
    let code: (MTLDevice, MTLCommandBuffer, CAMetalDrawable?) -> ()
    
    public init(code: @escaping (MTLDevice, MTLCommandBuffer, CAMetalDrawable?) -> ()) {
        self.code = code
    }
}
