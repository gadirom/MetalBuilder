import MetalKit
import SwiftUI

// BlitBuffer pass
class BlitBufferPass: MetalPass{
    
    var libraryContainer: LibraryContainer?
    
    let component: BlitBuffer
    
    init(_ component: BlitBuffer){
        self.component = component
    }
    func setup(renderInfo: GlobalRenderInfo){
    }
    func encode(passInfo: MetalPassInfo) throws {
        let commandBuffer = passInfo.getCommandBuffer()
        
        guard let inBuffer = component.inBuffer
        else{
            print("BlitBuffer: no inBuffer!")
            return
        }
        guard let outBuffer = component.outBuffer
        else{
            print("BlitBuffer: no outBuffer!")
            return
        }
        let elementSize = inBuffer.elementSize
        let count: Int
        if let c = component.count{
            count = c
        }else{
            count = inBuffer.count
        }
        
        let size = count*elementSize
        let inOffset = component.sourceOffset*size
        let outOffset = component.destinationOffset*size

        let blitBufferEncoder = commandBuffer.makeBlitCommandEncoder()
        blitBufferEncoder?.copy(from: inBuffer.mtlBuffer!, sourceOffset: inOffset,
                                to: outBuffer.mtlBuffer!, destinationOffset: outOffset,
                                size: size)
        blitBufferEncoder?.endEncoding()
    }
}
