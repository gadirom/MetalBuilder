
import MetalKit
import SwiftUI

// draw code pass
final class CPUCodePass: MetalPass{
    let component: CPUCode
    
    var device: MTLDevice!
    init(_ component: CPUCode){
        self.component = component
    }
    func setup(device: MTLDevice, library: MTLLibrary) {
        self.device = device
    }
    func encode(_ commandBuffer: MTLCommandBuffer, _ drawable: CAMetalDrawable?) {
        component.code(device, commandBuffer, drawable)
    }
}
