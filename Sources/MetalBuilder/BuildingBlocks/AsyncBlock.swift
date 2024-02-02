import MetalKit
import SwiftUI

/// Building block for async dispatch
public struct AsyncBlock<T: AsyncParameters>: MetalBuildingBlock {
    public init(context: MetalBuilderRenderingContext,
                asyncGroupInfo: AsyncGroupInfo<T>,
                isDrawing: MetalBinding<Bool> = .constant(true)
//                predicate: @escaping () -> (Bool) = { true }
    ) {
        self.context = context
        self._isDrawing = isDrawing
        self.asyncGroupInfo = asyncGroupInfo
//        self.predicate = predicate
    }
    
    public var context: MetalBuilderRenderingContext
    
    public var helpers: String = ""
    public var librarySource: String = ""
    public var compileOptions: MetalBuilderCompileOptions? = nil
    
    var _asyncContent: (()->MetalContent)?
    var _processResultContent: (()->MetalContent)?
    
    @MetalBinding var isDrawing: Bool
    
    let asyncGroupInfo: AsyncGroupInfo<T>
    
    func onCompleteAsync(){
        print("async: drawing = true")
        self.isDrawing = true
    }
    
    public func setup() {
        asyncGroupInfo.completion = {_ in
            onCompleteAsync()
        }
    }
    
    @MetalState var readyToSetReady = false
    
    public var metalContent: MetalContent{
        AsyncGroup(info: asyncGroupInfo) {
            EncodeGroup(metalContent: _asyncContent!)
//            ManualEncode{_,_ in
//                isDrawing = true
//            }
        }
        EncodeGroup(active: asyncGroupInfo.complete) {
            ManualEncode{device,_ in
                if readyToSetReady{
                    readyToSetReady = false
//                    print("run: check predicate")
//                    if predicate(){
//                        print("rerun for predicate")
//                        try! asyncGroupInfo.run()
//                    }
                    print("async block: drawing = false")
                    isDrawing = false
                    asyncGroupInfo.setReady()
                    return
                }else{
                    readyToSetReady = true
                }
            }
        }
        EncodeGroup(active: $readyToSetReady,
                    metalContent: _processResultContent!)
    }
}

public extension AsyncBlock{
    func asyncContent(@MetalResultBuilder  metalContent: @escaping ()->MetalContent)->Self{
        var a = self
        a._asyncContent = metalContent
        return a
    }
    func processResult(@MetalResultBuilder metalContent: @escaping ()->MetalContent)->Self{
        var a = self
        a._processResultContent = metalContent
        return a
    }
}
