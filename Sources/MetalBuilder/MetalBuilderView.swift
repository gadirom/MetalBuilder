
import MetalKit
import SwiftUI

public struct MetalBuilderView: UIViewRepresentable {
    
    @Environment(\.scenePhase) var scenePhase
    
    public let librarySource: String
    public let helpers: String
    @Binding public var isDrawing: Bool
    @MetalResultBuilder public let metalContent: MetalRenderingContent
    
    var viewSettings = MetalBuilderViewSettings()
    
    public init(librarySource: String = "",
                helpers: String = "",
                isDrawing: Binding<Bool>,
                viewSettings: MetalBuilderViewSettings?,
                @MetalResultBuilder metalContent: @escaping MetalRenderingContent){
        self.librarySource = librarySource
        self.helpers = helpers
        self._isDrawing = isDrawing
        self.metalContent = metalContent
    }
    
    public func makeCoordinator() -> Coordinator {
        //print("make coordinator")
        return Coordinator()
    }
    public func makeUIView(context: Context) -> UIView {
 
        let mtkView = MTKView()
        
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        //mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        
        context.coordinator.setupRenderer(librarySource: librarySource,
                                          helpers: helpers,
                                          pixelFormat: mtkView.colorPixelFormat,
                                          metalContent: metalContent,
                                          scaleFactor: Float(mtkView.contentScaleFactor))
        
        return mtkView
    }
    public func updateUIView(_ uiView: UIView, context: Context){
        context.coordinator.isDrawing = isDrawing
        
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
        
        var device: MTLDevice!
        var renderer: MetalBuilderRenderer?
        
        var isDrawing = false
        var viewSettings = MetalBuilderViewSettings()
        
        var background = false
        
        override init(){
            super.init()
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.device = metalDevice
            }
        }
        
        func setupRenderer(librarySource: String, helpers: String,
                           pixelFormat: MTLPixelFormat,
                           metalContent: MetalRenderingContent,
                           scaleFactor: Float){
            do{
                renderer =
                try MetalBuilderRenderer(device: device,
                                         pixelFormat: pixelFormat,
                                         librarySource: librarySource,
                                         helpers: helpers,
                                         renderingContent: metalContent)
                renderer?.setScaleFactor(scaleFactor)
            }catch{ print(error) }
        }
        
        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            applyViewSettings(view)
            renderer?.setSize(size: size)
            viewSettings.onResizeCode?(size)
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
