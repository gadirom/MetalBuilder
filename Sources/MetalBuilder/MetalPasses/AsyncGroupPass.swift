import MetalKit
import SwiftUI

// MPSUnaryPass
class AsyncGroupPass{
    
    var libraryContainer: LibraryContainer?
    let passes: [MetalPass]
    let info: AsyncGroupInfo
    
    init(_ passes: [MetalPass], info: AsyncGroupInfo){
        self.passes = passes
        self.info = info
        info.pass = self
    }
    func setup(renderInfo: GlobalRenderInfo, commandQueue: MTLCommandQueue) throws{
        info.commandQueue = commandQueue
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
