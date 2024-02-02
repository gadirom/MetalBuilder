import MetalKit
import SwiftUI

//protocol AsyncGroupPassProtocol{
//    
//}

public class AsyncGroupPass: MetalPass{
    
    var libraryContainer: LibraryContainer?
    let passes: [MetalPass]
    let info: AsyncGroupInfoProtocol
    
    init(_ passes: [MetalPass], info: AsyncGroupInfoProtocol){
        self.passes = passes
        self.info = info
        info.pass = self
    }
    func setup(renderInfo: GlobalRenderInfo) throws{
        info.commandQueue = renderInfo.device.makeCommandQueue()
        for pass in passes {
            try pass.setup(renderInfo: renderInfo)
        }
    }
    func prerun(renderInfo: GlobalRenderInfo) throws{
        for pass in passes {
            try pass.prerun(renderInfo: renderInfo)
        }
    }
    func encode(passInfo: MetalPassInfo) throws {
        for pass in passes {
            try pass.encode(passInfo: passInfo)
        }
    }
}
