import AVFoundation
#if(!os(visionOS))
final public class CameraConfiguration{
    public init(){
    }
    
    public var position: AVCaptureDevice.Position = .back{
        willSet{
            if newValue != position{
                changed = true
            }
        }
    }
    public var videoOrientation: AVCaptureVideoOrientation = .portrait{
        willSet{
            if newValue != videoOrientation{
                changed = true
            }
        }
    }
    
    @MetalState public var ready = false
    
    public var isVideoMirrored: Bool = false
    
    public var analysis: ((CVPixelBuffer) -> ())?
    
    private(set) var changed: Bool = true

}

public struct Camera: MetalBuildingBlock{
    public init(context: MetalBuilderRenderingContext,
                texture: MTLTextureContainer,
                configuration: CameraConfiguration) {
        self.context = context
        self.texture = texture
        self.cameraConfiguration = configuration
    }
    
    public var context: MetalBuilderRenderingContext
    
    //Parameters
    let texture: MTLTextureContainer
    
    //Inner states
    @MetalState private var cameraCapture = false
    @MetalState private var createTexture = true
    @MetalState private var pixelBuffer: CVPixelBuffer?
    
    private let cameraConfiguration: CameraConfiguration
    
    private let camera = CameraCapture()
    
    public var metalContent: MetalContent{
        ManualEncode{
            if cameraConfiguration.changed{
                camera.setupCaptureSession(configuration: cameraConfiguration)
            
                cameraCapture = true
                createTexture = true
                cameraConfiguration.ready = false
            }
        }
        EncodeGroup(active: $cameraCapture){
            ManualEncode{_,_ in
                if let pixelBuffer = camera.pixelBuffer{
                    self.pixelBuffer = pixelBuffer
                    cameraConfiguration.ready = true
                }
                if let pixelBuffer = pixelBuffer{
                    cameraConfiguration.analysis?(pixelBuffer)
                }
            }
            EncodeGroup(active: cameraConfiguration.$ready){
                CVPixelBufferYCbCbToRGBTexture(context: context,
                                       buffer: $pixelBuffer,
                                       texture: texture,
                                       createTexture: $createTexture)
            }
        }
    }
}
#endif
