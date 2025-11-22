//
//  GIFPlayerController.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 21. 11. 2025..
//

import ImageIO
import CoreGraphics
import SwiftUI
import MetalKit
import AVFoundation

@Observable
final public class GIFPlayerController{
    
    public init(){
        //deturmine max frames and write to Player max frames
        maxAllowedFramesForGIF = 2048
    }
    
    public var maxAllowedFramesForGIF: Int
    
    public var isPlaying: Bool = false{
        didSet{
            if isPlaying{
                if _currentTime == frameTiming?.duration{
                    seek(to: .zero)
                }
            }
        }
    }
    
    public var isBlockingPlayback: Bool = false //  to block playback if seeking but holding
    
    //public var shouldRestartPlayback: Bool = false // if was holding near while playing
    
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
    public var gifIsLoaded: Bool = false
    
    public var loop: Bool = true
    
    public var orientation: CGAffineTransform?
    
    public var errorHandler: ((MetalBuilderVideoPlayerError) -> ())?
//    @MainActor
//    public var formatDescriptions: [CMFormatDescription]?
    
    internal var frameTiming: FrameTiming?{
        didSet{
            duration = frameTiming?.duration ?? .zero
        }
    }
    
    @ObservationIgnored
    @MetalState public var nextFrameReady: Bool = false
    
    internal var _currentTime: CMTime = .zero
    
    @ObservationIgnored
    internal var currentFrameIndex: Int = 0
    
    @ObservationIgnored
    internal var isSeeking = false
    
    @ObservationIgnored
    internal var timeSinceLastFrame: Float = .zero
    
    @ObservationIgnored
    internal let asyncGroupInfo = AsyncGroupInfo<GIFLoader.AsyncParameters>()
    
    @ObservationIgnored
    internal let framesTextureArray = MTLTextureContainer(
        .init()
        .type(.type2DArray)
        //.pixelFormat(.rgba8Unorm)
        .manual()
    )
    
    @ObservationIgnored
    private var shouldClose = false // if close() run when asyngGroup is busy
}

internal extension GIFPlayerController{
    internal func onLoaded(){
        
        if shouldClose{
            close()
            return
        }
        
        gifIsLoaded = true
        isSeeking = true // show first frame
        currentFrameIndex = 0
        _currentTime = .zero
    }
    
    internal func seek(to time: CMTime) {
        guard let frameTiming
        else{ return }
        
        let newFrameIndex = frameTiming.frameIndex(for: time)
        if newFrameIndex != currentFrameIndex{
            currentFrameIndex = newFrameIndex
            isSeeking = true
        }else{
            isSeeking = false
        }
    }
    
    func calculateNextFrame(_ timeInterval: Float) -> Bool{
        guard gifIsLoaded
        else{
            nextFrameReady = false
            return false
        }
        
        if isSeeking{
            nextFrameReady = true
            isSeeking = false
            timeSinceLastFrame = 0
            
            return true
        }
        
        guard let frameTiming
        else{ return false }
        
        nextFrameReady = false
        
        if isPlaying && !isBlockingPlayback{
            let currentFrameDuration = Float(frameTiming.frameDurations[currentFrameIndex])
            let actualDuration = timeSinceLastFrame + timeInterval
            if actualDuration >= currentFrameDuration{
                
                currentFrameIndex += 1
                if currentFrameIndex >= frameTiming.frameCount{
                    if loop{
                        currentFrameIndex = 0
                        
                    }else{
                        currentFrameIndex = frameTiming.frameCount-1
                        _currentTime = frameTiming.duration
                        isPlaying = false
                        return false
                    }
                    
                }
                timeSinceLastFrame = Float(actualDuration - currentFrameDuration)
                
                nextFrameReady = true
            }else{
                nextFrameReady = false
                timeSinceLastFrame = Float(actualDuration)
            }
            _currentTime = CMTime(
                seconds: frameTiming.frameTime(for: currentFrameIndex) + Double(timeSinceLastFrame),
                preferredTimescale: 600)
        }

        return nextFrameReady
    }
}

public extension GIFPlayerController{
    func load(_ url: URL) throws{
        currentFrameIndex = 0
        try asyncGroupInfo.run(.init(url: url),
                               once: false,
                               captureAsync: false)
    }
    
    func close(){
        
        if asyncGroupInfo.busy.wrappedValue{
            shouldClose = true
            return
        }
        
        shouldClose = false
        
        isPlaying = false
        gifIsLoaded = false
        
        frameTiming = nil

        framesTextureArray.texture = nil
        //empty cache!!
    }
}
