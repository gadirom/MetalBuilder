import MetalKit

protocol MetalPass{
    //restartEncode is here to avoid downcasting to CPUComputePass
    var restartEncode: Bool { get }
    
    var libraryContainer: LibraryContainer? { get set }
    func setup(device: MTLDevice) throws
    func encode(_ commandBuffer: MTLCommandBuffer,_ drawable: CAMetalDrawable?) throws
}
