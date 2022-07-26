
import MetalKit
import SwiftUI

public struct MetalBuilderView: UIViewRepresentable {
    
    @Environment(\.scenePhase) var scenePhase
    
    public let librarySource: String
    public let helpers: String
    @Binding public var isDrawing: Bool
    @MetalResultBuilder public let metalContent: MetalBuilderContent
    
    var viewSettings = MetalBuilderViewSettings()
    
    var onResizeCode: ((CGSize)->())?
    
    /// The wrapper for MTKView that takes `MetalBuilderContent` to dispatch
    /// - Parameters:
    ///   - librarySource: your Metal code (can be empty if you pass the code via components of `MetalBuilderContent`)
    ///   - helpers: the Metal helper functions that you call from your shaders
    ///   - isDrawing: the boolean binding to control rendering: you may run and stop the rendering by setting the binded value to `true` or `false`.
    ///   - viewSettings: the common setting of MTKView gathered in MetalBuilderViewSettings struct
    ///   - metalContent: the ResultBuilder closure with all the information on your rendering pipelines
    ///
    ///   
    public init(librarySource: String = "",
                helpers: String = "",
                isDrawing: Binding<Bool>?=nil,
                viewSettings: MetalBuilderViewSettings?=nil,
                @MetalResultBuilder metalContent: @escaping MetalBuilderContent){
        self.librarySource = librarySource
        self.helpers = helpers
        if let isDrawing = isDrawing{
            self._isDrawing = isDrawing
        }else{
            self._isDrawing = Binding<Bool>.constant(true)
        }
        self.metalContent = metalContent
        if let viewSettings = viewSettings{
            self.viewSettings = viewSettings
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        //print("make coordinator")
        return Coordinator()
    }
    public func makeUIView(context: Context) -> UIView {
 
        let mtkView = MTKView()
        
        mtkView.delegate = context.coordinator
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        //mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        
        let renderInfo = GlobalRenderInfo(device: mtkView.device!,
                                          depthStencilPixelFormat: viewSettings.depthStencilPixelFormat,
                                          pixelFormat: mtkView.colorPixelFormat)
        
        context.coordinator.setupRenderer(librarySource: librarySource,
                                          helpers: helpers,
                                          renderInfo: renderInfo,
                                          metalContent: metalContent,
                                          scaleFactor: Float(mtkView.contentScaleFactor))
        
        return mtkView
    }
    public func updateUIView(_ uiView: UIView, context: Context){
        context.coordinator.isDrawing = isDrawing
        context.coordinator.onResizeCode = onResizeCode
        context.coordinator.viewSettings = viewSettings
        
        switch scenePhase{
        case .background:
            if !context.coordinator.background{
                context.coordinator.background = true
                context.coordinator.enterBackground()
            }
        case .active, .inactive:
            if  context.coordinator.background{
                context.coordinator.background = false
                context.coordinator.exitBackground()
            }
        @unknown default:
            break
        }
    }
    public class Coordinator: NSObject, MTKViewDelegate {
        
        //var device: MTLDevice!
        var renderer: MetalBuilderRenderer?
        
        var wasInitialized = false
        
        var isDrawing = false
        var onResizeCode: ((CGSize)->())?
        var viewSettings = MetalBuilderViewSettings()
        
        var background = false
        
        override init(){
            super.init()
            
        }
        
        func setupRenderer(librarySource: String, helpers: String,
                           renderInfo: GlobalRenderInfo,
                           metalContent: MetalBuilderContent,
                           scaleFactor: Float){
            do{
                renderer =
                try MetalBuilderRenderer(renderInfo: renderInfo,
                                         librarySource: librarySource,
                                         helpers: helpers,
                                         renderingContent: metalContent)
                renderer?.setScaleFactor(scaleFactor)
            }catch{ print(error) }
        }
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            applyViewSettings(view)
            renderer?.setSize(size: size)
            onResizeCode?(size)
            wasInitialized = true
        }
        
        func applyViewSettings(_ view: MTKView){
            
            if let preferredFramesPerSecond = viewSettings.preferredFramesPerSecond{
                view.preferredFramesPerSecond = preferredFramesPerSecond
            }
            
            if let framebufferOnly = viewSettings.framebufferOnly{
                view.framebufferOnly = framebufferOnly
            }
           
            if let clearColor = viewSettings.clearColor{
                view.clearColor = clearColor
            }
            
            //Depth routine
            if let clearDepth = viewSettings.clearDepth{
                view.clearDepth = clearDepth
            }
            if let depthStencilPixelFormat = viewSettings.depthStencilPixelFormat{
                view.depthStencilPixelFormat = depthStencilPixelFormat
            }
        }
    
        public func draw(in view: MTKView) {
            guard wasInitialized
            else{ return }
            
            guard isDrawing
            else{ return }
            
            guard let drawable = view.currentDrawable
            else { return }
            
            guard let renderPassDescriptor = view.currentRenderPassDescriptor
            else { return }
            
            do {
                try renderer?.draw(drawable: drawable,
                                   renderPassDescriptor: renderPassDescriptor)
            } catch { print(error) }
        }
        
        public func enterBackground(){
            renderer?.pauseTime()
        }
        public func exitBackground(){
            renderer?.resumeTime()
        }
    }
}
