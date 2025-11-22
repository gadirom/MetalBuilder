//
//  process.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 17. 11. 2025..
//

import MetalKit
import AVFoundation

extension MBVideoController{
    //nonisolated
    func process(device: MTLDevice, textureContainer: MTLTextureContainer){
        
        //print("process")
        
        guard (isPlaying && !isBlockingPlayback) || isSeeking
        else{ return }
        
        //print("tried to get frame for time: ", _currentTime)
        //if isSeeking{ print("while seeking") }
        
        if let (pixelBuffer, time) = getPixelBufferAndTime(
            //currentTime: isSeeking ? _currentTime : nil),
            currentTime: nil),
           let texture = createTexture(device: device,
                                       pixelBuffer: pixelBuffer){
            
            textureContainer.texture = texture
            
            //print("frame ready, for time: ", time)
            
            if seekingIsFinished{
                seekingIsFinished = false
                isSeeking = false
                //_currentTime = time
            }else{
                if !isSeeking{
                    _currentTime = time
                }
            }
            
            self.nextFrameReady = true
        }
    }
    
    func getPixelBufferAndTime(currentTime: CMTime?) -> (CVPixelBuffer, CMTime)?{
        
        guard let videoPlayerItemOutput
        else{
            return nil
        }
        
        let currentTime = currentTime ?? videoPlayerItemOutput
            .itemTime(forHostTime: CACurrentMediaTime())
        
        if videoPlayerItemOutput.hasNewPixelBuffer(forItemTime: currentTime),
            let buffer = videoPlayerItemOutput
                .copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil){
            
            return (buffer, currentTime)
        }
        return nil
    }
    
    func createTexture(device: MTLDevice, pixelBuffer: CVPixelBuffer) -> MTLTexture?{

        if textureCache == nil{
            
            let chacheAttributes = [kCVMetalTextureUsage: MTLTextureUsage.shaderRead] as CFDictionary
            
            let textureAttributes = [:] as CFDictionary
            
            let ret = CVMetalTextureCacheCreate(
                kCFAllocatorDefault,
                chacheAttributes,
                device,
                textureAttributes,
                &textureCache)
            
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
