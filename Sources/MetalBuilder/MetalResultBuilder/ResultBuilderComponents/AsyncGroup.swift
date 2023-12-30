import SwiftUI
import MetalKit

public func not(_ arg: MetalBinding<Bool>) -> MetalBinding<Bool>{
    MetalBinding<Bool>.init {
        !arg.wrappedValue
    } set: {
        arg.wrappedValue = !$0
    }
}

public class AsyncGroupInfo{
    public init(label: String = "Async Queue",
                runOnStartup: Bool=false,
                rerun: Bool=true){ //rerun if called when busy(e.g. to match probable changed value)
        self.label = label
        self.runOnStartup = runOnStartup
        self.rerunIfCalledWhenBusy = rerun
        busy = MetalBinding<Bool>.init{
            self._busy
        } set: {
            self._busy = $0
        }
        complete = MetalBinding<Bool>.init{
            self._complete
        } set: {
            self._complete = $0
        }
        wasCompleteOnce = MetalBinding<Bool>.init{
            self._wasCompleteOnce
        } set: {
            self._wasCompleteOnce = $0
        }
    }
    
    public var busy: MetalBinding<Bool>!
    public var complete: MetalBinding<Bool>!
    public var wasCompleteOnce: MetalBinding<Bool>!
    public func setReady(){
        complete.wrappedValue = false
    }

    var _wasCompleteOnce = false
    var _complete: Bool = false{
        didSet{
            if _complete == false{
                _busy = false
            }else{
                _wasCompleteOnce = true
            }
        }
    }
    var _busy: Bool = true
    
    var runOnStartup: Bool
    var rerunIfCalledWhenBusy: Bool
    
    private let functionCheckQueue = DispatchQueue(label: "Metal Builder async group check queue",
                                                   attributes: .concurrent)
    private let functionQueue = DispatchQueue(label: "Metal Builder async group function queue",
                                              //qos: .background,
                                              attributes: .concurrent)
    var wasCalledWhenBusy: Bool = false
    
    //var renderInfo: GlobalRenderInfo!
    var commandQueue: MTLCommandQueue!{
        didSet{
            commandQueue.label = self.label
        }
    }
    var label: String
    var commandBuffer: MTLCommandBuffer!
    var pass: AsyncGroupPass!
    
    public func run(once: Bool=false) throws{
        functionCheckQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            guard !self.busy.wrappedValue
            else {
                print("running: busy")
                if !once {
                    self.wasCalledWhenBusy = true
                }
                return
            }
            
            self._busy = true
            
            try! self.dispatch(once: once)
        }
    }
    
    func startup(_ device: MTLDevice){
        _busy = false
        if runOnStartup{
            try! dispatch(once: true)
        }
    }
    
    func dispatch(once: Bool) throws{
        functionQueue.sync{
            self.commandBuffer = try! self.startEncode()
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            
            let passInfo = MetalPassInfo(getCommandBuffer: self.getCommandBuffer,
                                         drawable: nil,
                                         depthStencilTexture: nil,
                                         renderPassDescriptor: renderPassDescriptor){
                try! self.restartEncode(commandBuffer: self.commandBuffer)
            }
            
            try! self.pass.encode(passInfo: passInfo)
            
            self.endEncode(commandBuffer: self.commandBuffer)
            
            self.functionCheckQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                if self.rerunIfCalledWhenBusy && !once && self.wasCalledWhenBusy{
                    self.wasCalledWhenBusy = false
                    try! self.dispatch(once: false)
                }else{
                    self._complete = true
                }
            }
        }
    }
}
extension AsyncGroupInfo{
    func getCommandBuffer()->MTLCommandBuffer{
        self.commandBuffer
    }
    func startEncode() throws -> MTLCommandBuffer{
        guard let commandBuffer = commandQueue.makeCommandBuffer()
        else{
            throw MetalBuilderRendererError
                .noCommandBuffer
        }
        return commandBuffer
    }
    func endEncode(commandBuffer: MTLCommandBuffer){
        
        commandBuffer.commit()

        commandBuffer.waitUntilCompleted()
    }
    func restartEncode(commandBuffer: MTLCommandBuffer) throws{
        endEncode(commandBuffer: commandBuffer)
        self.commandBuffer = try startEncode()
    }
}

/// Encodes a group of components for async dispatch.
public struct AsyncGroup: MetalBuilderComponent{
    
    var info: AsyncGroupInfo
    //public let librarySource: String?
    @MetalResultBuilder public let metalContent: MetalContent
    
    /// Creates an async group component.
    /// - Parameters:
    ///   - info: reference to the object that contains data for controlling the group's dispatch.
    ///   - metalContent: The ResultBuilder closure containing MetalBuilder components.
    public init(info: AsyncGroupInfo,
                //librarySource: String? = nil,
                @MetalResultBuilder metalContent: ()->MetalContent) {
        self.info = info
        self.metalContent = metalContent()
    }
}
