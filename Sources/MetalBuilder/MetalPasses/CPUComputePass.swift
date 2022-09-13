
import MetalKit
import SwiftUI

// CPU compute pass
final class CPUComputePass: MetalPass{
    
    let restartEncode = true
    
    let component: CPUCompute
    
    var libraryContainer: LibraryContainer?
    var device: MTLDevice!
    
    init(_ component: CPUCompute){
        self.component = component
    }
    func setup(device: MTLDevice) {
        self.device = device
    }
    func encode(_ commandBuffer: MTLCommandBuffer, _ drawable: CAMetalDrawable?) {
        component.code(device)
    }
}
