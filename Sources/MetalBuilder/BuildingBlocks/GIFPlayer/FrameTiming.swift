//
//  FrameTiming.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 22. 11. 2025..
//

import CoreMedia

struct FrameTiming {
    let frameDurations: [TimeInterval]
    let cumulativeTimes: [TimeInterval]
    private let totalDuration: TimeInterval
    
    init(frameDurations: [TimeInterval]) {
        
        self.frameDurations = frameDurations
        
        var cumulative: [TimeInterval] = []
        var runningTotal: TimeInterval = 0
        
        for duration in frameDurations {
            runningTotal += duration
            cumulative.append(runningTotal)
        }
        
        self.cumulativeTimes = cumulative
        self.totalDuration = runningTotal
    }
    
    func frameTime(for index: Int) -> TimeInterval{
        guard !cumulativeTimes.isEmpty else { return 0 }
        guard index <= frameCount else { return totalDuration }
        guard index > 0 else { return 0 }
        
        return cumulativeTimes[index-1]
    }
    
    func frameIndex(for time: CMTime) -> Int {
        guard !cumulativeTimes.isEmpty else { return 0 }
        
        let seconds = CMTimeGetSeconds(time)
        guard seconds.isFinite, seconds >= 0 else { return 0 }
        
        // If time exceeds total duration, return last frame
        if seconds >= totalDuration {
            return cumulativeTimes.count - 1
        }
        
        // Binary search to find the frame index
        var low = 0
        var high = cumulativeTimes.count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            let midTime = cumulativeTimes[mid]
            
            if seconds < midTime {
                // Check if this is the first frame that contains the time
                if mid == 0 || seconds >= cumulativeTimes[mid - 1] {
                    return mid
                }
                high = mid - 1
            } else {
                low = mid + 1
            }
        }
        
        return cumulativeTimes.count - 1 // fallback
    }
    
    // Optional: Helper to get total duration
    var duration: CMTime {
        CMTime(seconds: totalDuration,
               preferredTimescale: 600)
    }
    
    // Optional: Helper to get frame count
    var frameCount: Int {
        cumulativeTimes.count
    }
}
