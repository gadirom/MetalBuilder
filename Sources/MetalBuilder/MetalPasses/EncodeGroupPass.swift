import MetalKit
import SwiftUI

// MPSUnaryPass
class EncodeGroupPass: MetalPass{
    
    var libraryContainer: LibraryContainer?
    let passes: [MetalPass]
    let repeating: Binding<Int>
    let active: Binding<Bool>
    
    init(_ passes: [MetalPass], repeating: Binding<Int>, active: Binding<Bool>){
        self.passes = passes
        self.repeating = repeating
        self.active = active
    }
    func setup(renderInfo: GlobalRenderInfo) throws{
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
  
        let repeating = repeating.wrappedValue * (active.wrappedValue ? 1:0)
        for _ in 0..<repeating{
            for pass in passes {
                try pass.encode(passInfo: passInfo)
            }
        }
    }
}
