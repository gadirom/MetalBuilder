import AVFoundation

class MetalBuilderTimer{
    
    public var time: Float{
        _time
    }
    
    private var _time: Float = 0
    private var startTime: Double = 0
    private var pausedTime: Double = 0
    private var justStarted = true
    private var paused = true
    
    private var manualPaused = false
    
//    private let timerQueue = DispatchQueue(label: "MetalBuilderTimer_Queue",
//                                           qos: .userInitiated)
    
    func count(){
        //timerQueue.sync {
            if justStarted {
                startTime = CFAbsoluteTimeGetCurrent()
                justStarted = false
                paused = false
            }
            if paused { return }
            _time = Float(CFAbsoluteTimeGetCurrent()-startTime)
        //}
    }
    //Pause and resume manually by the client
    func manualPause(){
            manualPaused = true
            pauseTime()
    }
    func manualResume(){
            manualPaused = false
            resumeTime()
    }
    //Pause and resume for going in and from background
    func backgroundPause(){
            pauseTime()
    }
    func backgroundResume(){
            if manualPaused { return }
            resumeTime()
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
