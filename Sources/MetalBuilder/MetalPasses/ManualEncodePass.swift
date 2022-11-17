
import MetalKit
import SwiftUI

// manual encoding pass
final class ManualEncodePass: MetalPass{
    
    var libraryContainer: LibraryContainer?
    
    let component: ManualEncode
    
    unowned var device: MTLDevice!
    
    init(_ component: ManualEncode){
        self.component = component
    }
    func setup(renderInfo: GlobalRenderInfo) throws{
        self.device = renderInfo.device
    }
    func encode(passInfo: MetalPassInfo) throws {
        let commandBuffer = passInfo.getCommandBuffer()
        component.code(device, commandBuffer, passInfo.drawable)
    }
}
