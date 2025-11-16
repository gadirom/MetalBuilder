//
//  MBVideoController.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 14. 11. 2025..
//

import AVFoundation

public final class MBVideoController{
    public init(){}
    
    @MetalState public var nextFrameReady: Bool = false
    @MetalState public var currentTime: TimeInterval = 0
    public var playingStatus: Bool{
        isPlaying
    }
    
    var statusObserver: NSKeyValueObservation?
    
    var videoPlayer = AVPlayer()
    var videoPlayerItemOutput: AVPlayerItemVideoOutput?
    
    private var textureCache: CVMetalTextureCache?
    private var cvTexture: CVMetalTexture?
    //private var pixelBuffer: CVPixelBuffer?
    
    @MetalState var isPlaying: Bool = false
    //@MetalState var createTexture = true
    
}
public extension MBVideoController{
    
    func close(){
        videoPlayer.pause()
        isPlaying = false
        self.videoPlayer.replaceCurrentItem(with: nil)
        self.videoPlayerItemOutput = nil
        self.statusObserver = nil
        
        //empty cache!!
    }
    
    func load(_ url: URL){
        let videoPlayerItem = AVPlayerItem(url: url)
        
        // Create an player
        self.videoPlayer.replaceCurrentItem(with: videoPlayerItem)
        
        
//        Looping!
//        player = AVQueuePlayer()
//        loopy = AVPlayerLooper(player: player as! AVQueuePlayer,
//                               templateItem: AVPlayerItem(url: u))
        let outputTransferFunction = AVVideoTransferFunction_ITU_R_709_2
        let videoColorProperties = [
            AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_2020,
            AVVideoTransferFunctionKey: outputTransferFunction,
            AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020
        ]
        
//        let videoColorProperties = [
//            AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
//            AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
//            AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
//        ]
        
        
//            AVVideoColorPrimariesKey: AVVideoColorPrimaries_P3_D65,
//            AVVideoTransferFunctionKey: AVVideoTransferFunction_Linear,
//            AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020
//        ]
        
        let outputVideoSettings = [
            AVVideoAllowWideColorKey: true,
            AVVideoColorPropertiesKey: videoColorProperties,
            kCVPixelBufferPixelFormatTypeKey as String:
                NSNumber(value: kCVPixelFormatType_64RGBAHalf)
        ] as [String : Any]
        
        // Create a player item video output
        let videoPlayerItemOutput = AVPlayerItemVideoOutput(
            outputSettings: outputVideoSettings
        )
        
        self.videoPlayerItemOutput = videoPlayerItemOutput
        
        statusObserver = videoPlayerItem.observe(\.status,
                                                  options: [.new, .old],
                                                  changeHandler: { playerItem, change in
            if playerItem.status == . readyToPlay {
                playerItem.add(videoPlayerItemOutput)
                //displayLink.add(to: •main, forMode: • common)
                self.videoPlayer.play()
                print("\(self.videoPlayer.currentItem?.status)")
                print("\(self.videoPlayer.error)")
                
            }
        })
        
        //createTexture = true
        
        print(videoPlayer.currentItem?.status)
        
    }
    
    func start(){
        videoPlayer.play()
        isPlaying = true
    }
    func stop(){
        videoPlayer.pause()
    }
    func seek(to timeInterval: TimeInterval) async {
        // Create a CMTime value for the passed in time interval.
        let time = CMTime(seconds: timeInterval, preferredTimescale: 600)
        await videoPlayer.seek(to: time)
    }

}

extension MBVideoController{
    
    func process(device: MTLDevice, textureContainer: MTLTextureContainer){
        
        guard isPlaying
        else{ return }
        
        if let (pixelBuffer, time) = getPixelBufferAndTime(),
           let texture = createTexture(device: device,
                                       pixelBuffer: pixelBuffer){
            
            textureContainer.texture = texture
            
            self.nextFrameReady = true
        }
    }
    
    func getPixelBufferAndTime() -> (CVPixelBuffer, TimeInterval)?{
        
        guard let videoPlayerItemOutput
        else{
            return nil
        }
        
        let currentTime = videoPlayerItemOutput
            .itemTime(forHostTime: CACurrentMediaTime())
        
        if videoPlayerItemOutput.hasNewPixelBuffer(forItemTime: currentTime),
            let buffer = videoPlayerItemOutput
                .copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil){
            
            return (buffer, currentTime.seconds)
        }
        return nil
    }
    
    func createTexture(device: MTLDevice, pixelBuffer: CVPixelBuffer) -> MTLTexture?{

        if textureCache == nil{
            let ret = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
            if ret != 0{
                print("Texture Cash creating error: \(ret)")
                return nil
            }
        }
        
        cvTexture = nil
        
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache!,
            pixelBuffer,
            nil,
            .rgba16Float,
            CVPixelBufferGetWidth(pixelBuffer),
            CVPixelBufferGetHeight(pixelBuffer),
            0,
            &cvTexture)
        
        if let cvTexture{
            return CVMetalTextureGetTexture(cvTexture)
        }
        
        return nil

    }
    
}
