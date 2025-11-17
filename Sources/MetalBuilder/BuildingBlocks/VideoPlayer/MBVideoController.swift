//
//  MBVideoController.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 14. 11. 2025..
//

import AVFoundation
import SwiftUI

@Observable
public final class MBVideoController{
    public init(){}
    
    public var isPlaying: Bool = false{
        didSet{
            if isPlaying{
                start()
            }else{
                stop()
            }
        }
    }
    
    public var isBlockingPlayback: Bool = false //  to block playback if seeking but holding
    
    public var currentTime: CMTime{
        get{
            _currentTime
        }
        set{
            if _currentTime != newValue{
                //seekedTime =
                _currentTime = newValue
                seek(to: newValue)
            }
        }
    }
    
    public var duration: CMTime = .zero
    public var videoIsLoaded: Bool = false
    
    public var loop: Bool = true
    
    @ObservationIgnored
    @MetalState public var nextFrameReady: Bool = false
    
    internal var _currentTime: CMTime = .zero
    
//    @ObservationIgnored
//    internal var seekedTime: CMTime?
    
    @ObservationIgnored
    internal var statusObserver: NSKeyValueObservation?
    @ObservationIgnored
    internal var videoPlayer = AVPlayer()
    @ObservationIgnored
    internal var videoPlayerItemOutput: AVPlayerItemVideoOutput?
    
    @ObservationIgnored
    internal var textureCache: CVMetalTextureCache?
    @ObservationIgnored
    internal var cvTexture: CVMetalTexture?
    
    @ObservationIgnored
    internal var isSeeking: Bool = false
    @ObservationIgnored
    internal var seekingIsFinished: Bool = false
//    @ObservationIgnored
//    internal var pendingTime: CMTime?

    internal func start(){
        videoPlayer.play()
    }
    internal func stop(){
        videoPlayer.pause()
    }
    
    internal func seek(to time: CMTime) {
        // Create a CMTime value for the passed in time interval.
        //let time = CMTime(seconds: timeInterval, preferredTimescale: 600)
        videoPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero){ finished in
            if finished{
                print("seeking finiished")
                self.seekingIsFinished = true
            }else{
                print("seeking not finished")
            }
        }
        isSeeking = true
    }
    
}
public extension MBVideoController{
    
    func close(){
        isPlaying = false
        self.videoPlayer.replaceCurrentItem(with: nil)
        self.videoPlayerItemOutput = nil
        self.statusObserver = nil
        
        //empty cache!!
    }

}
