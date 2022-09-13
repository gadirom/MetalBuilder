
import MetalKit
import SwiftUI

/// CPUCompute Component
///
/// runs plain code in draw function and restarts encoding
/// Use this component to perform intermediate computations on CPU.
/// Components previous to `CPUCompute` will be dispatched in separate Compute Buffer, and the code provided with this component will run after it's dispatch is finished.
/// The subsequent components will be encoded in a separate Command Buffer.
public struct CPUCompute: MetalBuilderComponent{
    
    let code: (MTLDevice) -> ()
    
    public init(code: @escaping (MTLDevice) -> ()) {
        self.code = code
    }
}
