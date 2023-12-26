
import MetalKit
import SwiftUI

/// The component for dispatching current command buffer and waiting for the results.
/// The next components will encode into a next command buffer after waiting for the previous dispatch to finish.
public struct GPUDispatchAndWait: MetalBuilderComponent{
    public init() {
    }
}
