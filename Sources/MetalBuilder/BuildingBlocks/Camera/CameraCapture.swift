
import MetalKit
import AVFoundation

#if(!os(visionOS))

public class CameraCapture: NSObject{
    
    public var pixelBuffer: CVPixelBuffer?
    var session: AVCaptureSession?
    
//    public init(){
//        super.init()
//    }
}
extension CameraCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func setupCaptureSession(configuration: CameraConfiguration) {
        
        guard let captureDevice = AVCaptureDevice
            .default(.builtInWideAngleCamera, for: .video,
                     position: configuration.position) else {
            fatalError("Error getting AVCaptureDevice.")
        }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            fatalError("Error getting AVCaptureDeviceInput.")
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.session = AVCaptureSession()
            self.session?.sessionPreset = .high
            self.session?.addInput(input)
            
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: .main)
            
            self.session?.addOutput(output)
            output.connections.first?.videoOrientation = configuration.videoOrientation
            output.connections.first?.isVideoMirrored = configuration.isVideoMirrored
            self.session?.startRunning()
        }
    }
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        
        if (CVPixelBufferGetPlaneCount(pixelBuffer) < 2) {
            return
        }
        self.pixelBuffer = pixelBuffer
    }
}

#endif
