
import MetalKit
import SwiftUI

/// ManualEncode Component
///
/// runs plain code in the  `draw` function.
/// Use this component to manually encode dispatches on current Command Buffer
public struct ManualEncode: MetalBuilderComponent{
    
    let code: (MTLDevice, MTLCommandBuffer, CAMetalDrawable?) -> ()
    
    public init(code: @escaping (MTLDevice, MTLCommandBuffer, CAMetalDrawable?) -> ()) {
        self.code = code
    }
}
