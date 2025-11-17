//
//  process.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 17. 11. 2025..
//

import MetalKit
import AVFoundation

extension MBVideoController{
    
    func process(device: MTLDevice, textureContainer: MTLTextureContainer){
        
        guard (isPlaying && !isBlockingPlayback) || isSeeking
        else{ return }
        
        if let (pixelBuffer, time) = getPixelBufferAndTime(),
           let texture = createTexture(device: device,
                                       pixelBuffer: pixelBuffer){
            
            textureContainer.texture = texture
            
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
    
    func getPixelBufferAndTime() -> (CVPixelBuffer, CMTime)?{
        
        guard let videoPlayerItemOutput
        else{
            return nil
        }
        
        let currentTime = videoPlayerItemOutput
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
