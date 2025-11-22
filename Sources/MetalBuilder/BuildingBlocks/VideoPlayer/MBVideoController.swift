//
//  MBVideoController.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 14. 11. 2025..
//

import AVFoundation
import SwiftUI

//@MainActor
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
    
    public var isBlockingPlayback: Bool = false{
        didSet{
            if !isBlockingPlayback && shouldRestartPlayback{
                shouldRestartPlayback = false
                if currentTime == duration{
                    playerItemDidPlayToEnd()
                }else{
                    videoPlayer.play()
                }
            }
        }
    } //  to block playback if seeking but holding
    
    public var shouldRestartPlayback: Bool = false // if was holding near while playing
    
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
    
    public var isMuted: Bool = false{
        didSet{
            videoPlayer.isMuted = isMuted
        }
    }
    
    public var orientation: CGAffineTransform?
    
    public var errorHandler: ((MetalBuilderVideoPlayerError) -> ())?
//    @MainActor
//    public var formatDescriptions: [CMFormatDescription]?
    
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
        if currentTime == duration{
            //print("should start from start")
            currentTime = .zero
            seek(to: .zero)
        }
        videoPlayer.play()
    }
    internal func stop(){
        videoPlayer.pause()
    }
    
    internal func seek(to time: CMTime) {
        //print(" seeking to time: ", time)
        // Create a CMTime value for the passed in time interval.
        //let time = CMTime(seconds: timeInterval, preferredTimescale: 600)
        //videoPlayer.automaticallyWaitsToMinimizeStalling = false
        if isPlaying{
            videoPlayer.pause() // for some reason this was needed to corectly jump to the ending frame
        }
        videoPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero){ finished in
            if finished{
                //print("seeking finiished")
                self.seekingIsFinished = true
                if self.isPlaying{
                    if self.isBlockingPlayback{
                        self.shouldRestartPlayback = true
                    }else{
                        self.videoPlayer.play() // this is needed (explained above)
                    }
                }
            }else{
                //print("seeking not finished")
            }
        }
        isSeeking = true
    }
    
}
public extension MBVideoController{
    func close(){
        isPlaying = false
        videoIsLoaded = false
        self.videoPlayerItemOutput = nil
        self.videoPlayer.replaceCurrentItem(with: nil)
        
        self.statusObserver = nil
        
        self.cvTexture = nil
        self.textureCache = nil

        
        //empty cache!!
    }

}
