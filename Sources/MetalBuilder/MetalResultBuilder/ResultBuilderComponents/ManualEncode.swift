
import MetalKit
import SwiftUI

/// The component to run CPU code.
///
/// Runs plain CPU code in the `draw` function.
/// Use this component to manually encode dispatches on the current command buffer.
public struct ManualEncode: MetalBuilderComponent{
    
    let code: (MTLDevice, MetalPassInfo) -> ()
    
    public init(code: @escaping (MTLDevice, MetalPassInfo) -> ()) {
        self.code = code
    }
}
