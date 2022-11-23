import AVFoundation

class MetalBuilderTimer{
    
    public var time: Float = 0
    
    var startTime: Double = 0
    var pausedTime: Double = 0
    var justStarted = true
    var paused = true
    
    func count(){
        if justStarted {
            startTime = CFAbsoluteTimeGetCurrent()
            justStarted = false
            paused = false
        }
        if paused { return }
        time = Float(CFAbsoluteTimeGetCurrent()-startTime)
        print(time)
    }
    
    func pauseTime(){
        guard !justStarted
        else{return}
        guard !paused
        else{return}
        pausedTime = CFAbsoluteTimeGetCurrent()
        paused = true
        print("time paused!")
    }
    func resumeTime(){
        guard !justStarted
        else{return}
        guard paused
        else{return}
        startTime += CFAbsoluteTimeGetCurrent()-pausedTime
        paused = false
        print("time resumed!")
    }
}
