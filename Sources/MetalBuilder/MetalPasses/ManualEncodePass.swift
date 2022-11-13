
import MetalKit
import SwiftUI

// manual encoding pass
final class ManualEncodePass: MetalPass{
    
    var libraryContainer: LibraryContainer?
    
    let component: ManualEncode
    
    var device: MTLDevice!
    
    init(_ component: ManualEncode){
        self.component = component
    }
    func setup(device: MTLDevice) {
        self.device = device
    }
    func encode(_ commandBuffer: MTLCommandBuffer,
                _ drawable: CAMetalDrawable?,
                _ restartEncode: () throws ->()) {
        component.code(device, commandBuffer, drawable)
    }
}
