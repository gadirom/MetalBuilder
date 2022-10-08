import MetalKit
import SwiftUI

// MPSUnaryPass
class EncodeGroupPass: MetalPass{
    let restartEncode = false
    
    var libraryContainer: LibraryContainer?
    let passes: [MetalPass]
    let repeating: Binding<Int>
    let active: Binding<Bool>
    
    init(_ passes: [MetalPass], repeating: Binding<Int>, active: Binding<Bool>){
        self.passes = passes
        self.repeating = repeating
        self.active = active
    }
    func setup(device: MTLDevice) throws{
        for pass in passes {
            try pass.setup(device: device)
        }
    }
    func encode(_ commandBuffer: MTLCommandBuffer,_ drawable: CAMetalDrawable?) throws {
        let repeating = repeating.wrappedValue * (active.wrappedValue ? 1:0)
        for _ in 0..<repeating{
            for pass in passes {
                try pass.encode(commandBuffer, drawable)
            }
        }
    }
}
