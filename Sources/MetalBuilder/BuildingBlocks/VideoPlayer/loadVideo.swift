//
//  loadVideo.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 17. 11. 2025..
//

import AVFoundation

public extension MBVideoController{
    func load(_ url: URL, outputColorProperties: VideoColorProperties) throws{
        
        videoIsLoaded = false
        
        
        let asset = AVURLAsset(url: url)
        let videoPlayerItem = AVPlayerItem(asset: asset)
        
        // Create an player
        self.videoPlayer.replaceCurrentItem(with: videoPlayerItem)
        
        
//        Looping!
//        player = AVQueuePlayer()
//        loopy = AVPlayerLooper(player: player as! AVQueuePlayer,
//                               templateItem: AVPlayerItem(url: u))
        
        let videoColorProperties = outputColorProperties.dict
            
        
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
            self.onLoaded(playerItem)
            
        })
        
        //createTexture = true
        
        print(videoPlayer.currentItem?.status)
        
    }
}

extension MBVideoController{
    
    func onLoaded(_ item: AVPlayerItem){
        if item.status == . readyToPlay, let videoPlayerItemOutput{
            item.add(videoPlayerItemOutput)
            
            //print("outputs: ", playerItem.outputs)
            
            //displayLink.add(to: •main, forMode: • common)
            //self.videoPlayer.play()
            self.videoIsLoaded = true
            
            self.duration = item.duration
            
            currentTime = .zero
            seek(to: .zero)
            
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerItemDidPlayToEnd),
                name: .AVPlayerItemDidPlayToEndTime,
                object: item)
            
            //print("\(self.videoPlayer.currentItem?.status)")
            //print("\(self.videoPlayer.error)")
            
        }
    }
    
    @objc
    func playerItemDidPlayToEnd(){
        if loop{
            currentTime = .zero
            seek(to: .zero)
            isPlaying = true
        }else{
            isPlaying = false
        }
    }
    
    func loadVideoMetadata(asset: AVURLAsset) throws{
        
        Task {
            
            let videoTracks = try await asset.loadTracks(withMediaCharacteristic: .visual)
            if videoTracks.isEmpty { return }
            
            //?????
            //            let hdrTracks = try await asset.loadTracks(withMediaCharacteristic: .containsHDRVideo)
            //            self.assetIsHDR = !hdrTracks.isEmpty
            
            let firstTrack = videoTracks[0]
            //self.contentSize = try await firstTrack.load(.naturalSize)
            //self.videoTransform = try await firstTrack.load(.preferredTransform)
            
            //var outputTransferFunction = AVVideoTransferFunction_Linear
            //if tonemappingMode == .auto {
            let formatDescriptions: [CMFormatDescription] = try await firstTrack.load(.formatDescriptions)
            
            if let primaryFormatDescription = formatDescriptions.first {
                if let transferFunctionValue = primaryFormatDescription.extensions[.transferFunction] {
                        let transferFunction = transferFunctionValue.propertyListRepresentation as! CFString
                        if transferFunction == CMFormatDescription.Extensions.Value.TransferFunction.itu_R_2020.rawValue {
                            // ITU_R_2020 requires special handling because there is no matching AVFoundation value for it.
                            // All of the other relevant transfer functions are spelled identically between CM and AV.
                            //outputTransferFunction = AVVideoTransferFunction_ITU_R_709_2
                        } else {
                            //outputTransferFunction = transferFunction as String
                        }
                        //print("Selected output transfer function: \(outputTransferFunction)")
                    }
                }
                if formatDescriptions.count > 1 {
                    print("Not handling multiple video format descriptions")
                }
            //}
            
            
        }
    }
}

