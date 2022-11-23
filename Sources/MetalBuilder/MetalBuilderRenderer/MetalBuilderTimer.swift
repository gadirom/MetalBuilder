import AVFoundation

class MetalBuilderTimer{
    
    public var time: Float{
        timerQueue.sync {
            _time
        }
    }
    
    var _time: Float = 0
    var startTime: Double = 0
    var pausedTime: Double = 0
    var justStarted = true
    var paused = true
    
    var manualPaused = false
    
    let timerQueue = DispatchQueue(label: "MetalBuilderTimer_Queue",
                                   qos: .userInitiated)
    
    func count(){
        timerQueue.sync {
            if justStarted {
                startTime = CFAbsoluteTimeGetCurrent()
                justStarted = false
                paused = false
            }
            if paused { return }
            _time = Float(CFAbsoluteTimeGetCurrent()-startTime)
        }
    }
    //Pause and resume manually by the client
    func manualPause(){
        timerQueue.sync {
            manualPaused = true
            pauseTime()
        }
    }
    func manualResume(){
        timerQueue.sync {
            manualPaused = false
            resumeTime()
        }
    }
    //Pause and resume for going in and from background
    func backgroundPause(){
        timerQueue.sync {
            pauseTime()
        }
    }
    func backgroundResume(){
        timerQueue.sync {
            if manualPaused { return }
            resumeTime()
        }
    }
    
    private func pauseTime(){
        guard !justStarted
        else{return}
        guard !paused
        else{return}
        pausedTime = CFAbsoluteTimeGetCurrent()
        paused = true
        print("time paused!")
    }
    private func resumeTime(){
        guard !justStarted
        else{return}
        guard paused
        else{return}
        startTime += CFAbsoluteTimeGetCurrent()-pausedTime
        paused = false
        print("time resumed!")
    }
}
