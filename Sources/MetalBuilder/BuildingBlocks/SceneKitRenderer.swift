import SceneKit

public struct SceneKitRenderer: MetalBuildingBlock, Renderable{
    public init(context: MetalBuilderRenderingContext, 
                  scene: MetalBinding<SCNScene?>) {
        self.context = context
        self._scene = scene
    }
    
    public var context: MetalBuilderRenderingContext
    public var helpers: String = ""
    public var librarySource: String = ""
    public var compileOptions: MetalBuilderCompileOptions? = nil
    public var renderableData = RenderableData()
    
    @MetalBinding var scene: SCNScene?
    
    @MetalState var renderer: SCNRenderer!
    
    public func startup(device: MTLDevice) {
        renderer = .init(device: device)
    }
    
    public var metalContent: MetalContent{
        ManualEncode{device, passInfo in
            if let scene{
                let (desc, vp) = passInfo.getRenderPassDescriptorAndViewport(renderableData: renderableData)
                let commBuf = passInfo.getCommandBuffer()
                renderer.scene = scene
                let viewport = CGRect(x: vp.originX, y: vp.originY,
                                      width: vp.width, height: vp.height)
                renderer.render(withViewport: viewport,
                                commandBuffer: commBuf,
                                passDescriptor: desc)
            }
        }
    }
    
}
