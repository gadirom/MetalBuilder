
import MetalKit
import SwiftUI

// CPU compute pass
final class GPUDispatchAndWaitPass: MetalPass{
    
    //let component: CPUCompute
    
    var libraryContainer: LibraryContainer?
    
    init(){
    }
    func setup(renderInfo: GlobalRenderInfo){
    }
    func encode(passInfo: MetalPassInfo) throws {
        try passInfo.restartEncode()
    }
}
