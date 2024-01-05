
import MetalKit
import SwiftUI
import MetalPerformanceShaders

// MPSUnaryPass
class MPSUnaryPass: MetalPass{
    
    var libraryContainer: LibraryContainer?
    
    let component: MPSUnary
    unowned var device: MTLDevice!
    
    var kernel: MPSUnaryImageKernel!
    
    //var kernel: MPSUnaryImageKernel!
    init(_ component: MPSUnary){
        self.component = component
    }
    func setup(renderInfo: GlobalRenderInfo){
        self.device = renderInfo.device
        self.kernel = component.initCode(renderInfo.device)
    }
    func encode(passInfo: MetalPassInfo) throws {
        
        let commandBuffer = passInfo.getCommandBuffer()
        for key in component.dict.keys{
            let value = component.dict[key]!.wrappedValue
            kernel.setValue(value, forKey: key)
        }
        if var inTexture = component.inTexture?.texture{
            var outTexture: MTLTexture?
            if component.outToDrawable{
                outTexture = passInfo.drawable?.texture
            }else{
                outTexture = component.outTexture?.texture
            }
            if let outTexture = outTexture{
                kernel.encode(commandBuffer: commandBuffer, sourceTexture: inTexture, destinationTexture: outTexture)
            }else{
                kernel.encode(commandBuffer: commandBuffer,
                              inPlaceTexture: &inTexture,
                              fallbackCopyAllocator: copyAllocator)
            }
        }
    }
}

public let copyAllocator: MPSCopyAllocator = { kernel, commandBuffer, texture in
    var d = TextureDescriptor()
        .type(.type2D)
        .pixelFormat(texture.pixelFormat)
        .fixedSize(CGSize(width: texture.width, height: texture.height))
        .usage([.shaderWrite, .shaderRead, .renderTarget])
    
//    d.textureType = .type2D
//    d.pixelFormat = texture.pixelFormat
//    d.width = texture.width
//    d.height = texture.height
//    d.usage = [.shaderWrite, .shaderRead]
    return commandBuffer.device.makeTexture(descriptor: d.mtlTextureDescriptor(viewportSize:[0,0])!)!
}
