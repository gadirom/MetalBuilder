import MetalKit
import SwiftUI

// MPSUnaryPass
class EncodeGroupPass: MetalPass{
    let restartEncode = false
    
    var libraryContainer: LibraryContainer?
    let passes: [MetalPass]
    let repeating: Binding<Int>
    
    init(_ passes: [MetalPass], repeating: Binding<Int>){
        self.passes = passes
        self.repeating = repeating
    }
    func setup(device: MTLDevice) throws{
        for pass in passes {
            try pass.setup(device: device)
        }
    }
    func encode(_ commandBuffer: MTLCommandBuffer,_ drawable: CAMetalDrawable?) throws {
        for _ in 0..<repeating.wrappedValue{
            for pass in passes {
                try pass.encode(commandBuffer, drawable)
            }
        }
    }
}
