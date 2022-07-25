import MetalKit

protocol MetalPass{
    func setup(device: MTLDevice, library: MTLLibrary) throws
    func encode(_ commandBuffer: MTLCommandBuffer,_ drawable: CAMetalDrawable?) throws
}
