
import MetalKit
import SwiftUI

/// The component to run calculations on CPU.
///
/// This component runs plain code in the draw function and restarts GPU encoding.
/// Use this component to perform intermediate computations on CPU.
/// The components previous to `CPUCompute` will be dispatched in separate command buffer,
/// and the code provided with this component will run after it's dispatch is finished.
/// The subsequent components will be encoded in a separate command buffer.
public struct CPUCompute: MetalBuilderComponent{
    
    let code: (MTLDevice) -> ()
    
    public init(code: @escaping (MTLDevice) -> ()) {
        self.code = code
    }
}
