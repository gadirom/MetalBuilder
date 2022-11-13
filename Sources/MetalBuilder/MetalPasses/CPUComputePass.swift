
import MetalKit
import SwiftUI

// CPU compute pass
final class CPUComputePass: MetalPass{
    
    let component: CPUCompute
    
    var libraryContainer: LibraryContainer?
    var device: MTLDevice!
    
    init(_ component: CPUCompute){
        self.component = component
    }
    func setup(device: MTLDevice) {
        self.device = device
    }
    func encode(_ commandBuffer: MTLCommandBuffer,
                _ drawable: CAMetalDrawable?,
                _ restartEncode: () throws ->()) throws{
        try restartEncode()
        component.code(device)
    }
}
