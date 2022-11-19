import AVFoundation

class CameraConfiguration{
    internal init(){}
    var position: AVCaptureDevice.Position?
    var videoOrientation: AVCaptureVideoOrientation?
    
    func changed(position: AVCaptureDevice.Position,
                 videoOrientation: AVCaptureVideoOrientation)->Bool{
        var changed = false
        if self.position != position{
            changed = true
            self.position=position
        }
        if self.videoOrientation != videoOrientation{
            changed = true
            self.videoOrientation=videoOrientation
        }
        return changed
    }
}

public struct Camera: MetalBuildingBlock{
    public init(context: MetalBuilderRenderingContext,
                texture: MTLTextureContainer,
                position: MetalBinding<AVCaptureDevice.Position>,
                videoOrientation: MetalBinding<AVCaptureVideoOrientation>,
                isVideoMirrored: MetalBinding<Bool>,
                ready: MetalBinding<Bool>,
                analysis: @escaping (CVPixelBuffer) -> ()) {
        self.context = context
        self.texture = texture
        self._position = position
        self._videoOrientation = videoOrientation
        self._isVideoMirrored = isVideoMirrored
        self.analysis = analysis
        self._ready = ready
    }
    
    public var context: MetalBuilderRenderingContext
    public var helpers = ""
    public var librarySource = ""
    public var compileOptions: MetalBuilderCompileOptions? = nil
    
    //Parameters
    let texture: MTLTextureContainer
    @MetalBinding var position: AVCaptureDevice.Position
    @MetalBinding var videoOrientation: AVCaptureVideoOrientation
    @MetalBinding var isVideoMirrored: Bool
    @MetalBinding var ready: Bool
    let analysis: (CVPixelBuffer)->()
    
    //Inner states
    @MetalState var cameraCapture = false
    @MetalState var createTexture = true
    @MetalState var camera: CameraCapture?
    @MetalState var pixelBuffer: CVPixelBuffer?
    
    let cameraConfiguration = CameraConfiguration()
    
    public var metalContent: MetalContent{
        EncodeGroup{//Setup Camera
                ManualEncode{ device,_,_ in
                    if cameraConfiguration.changed(position: position,
                                                   videoOrientation: videoOrientation){
                        camera = CameraCapture(position: position,
                                               videoOrientation: videoOrientation,
                                               isVideoMirrored: isVideoMirrored)
                    
                        cameraCapture = true
                        createTexture = true
                        ready = false
                    }
            }
        }
        EncodeGroup(active: $cameraCapture){
            ManualEncode{_,_,_ in
                if let pixelBuffer = camera!.pixelBuffer{
                    self.pixelBuffer = pixelBuffer
                    ready = true
                }
                if let pixelBuffer = pixelBuffer{
                    analysis(pixelBuffer)
                }
            }
            EncodeGroup(active: $ready){
                CVPixelBufferYCbCbToRGBTexture(context: context,
                                       buffer: $pixelBuffer,
                                       texture: texture,
                                       createTexture: $createTexture)
            }
        }
    }
}
