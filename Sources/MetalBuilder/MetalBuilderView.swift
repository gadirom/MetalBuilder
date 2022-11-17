
import MetalKit
import SwiftUI

public struct MetalBuilderView: UIViewRepresentable {
    
    @Environment(\.scenePhase) var scenePhase
    
    public let librarySource: String
    public let helpers: String
    @Binding public var isDrawing: Bool
    @MetalResultBuilder public let metalContent: MetalRenderingContent
    let onResizeCode: ((CGSize)->())?
    
    public init(librarySource: String = "",
                helpers: String = "",
                isDrawing: Binding<Bool>,
                @MetalResultBuilder metalContent: @escaping MetalRenderingContent){
        self.init(librarySource: librarySource,
                  helpers: helpers,
                  isDrawing: isDrawing,
                  metalContent: metalContent,
                  onResizeCode: nil)
    }
    init(librarySource: String,
         helpers: String,
         isDrawing: Binding<Bool>,
         metalContent: @escaping MetalRenderingContent,
         onResizeCode: ((CGSize)->())?) {
        self.librarySource = librarySource
        self.helpers = helpers
        self._isDrawing = isDrawing
        self.metalContent = metalContent
        self.onResizeCode = onResizeCode
    }
    
    public func onResize(perform: @escaping (CGSize)->())->MetalBuilderView{
        MetalBuilderView(librarySource: librarySource,
                         helpers: helpers,
                         isDrawing: $isDrawing,
                         metalContent: metalContent,
                         onResizeCode: perform)
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
        mtkView.framebufferOnly = false
        //mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        //Depth routine
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.clearDepth = 1
        
        
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
        context.coordinator.onResizeCode = onResizeCode
        
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
        var onResizeCode: ((CGSize)->())?
        
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
            renderer?.setSize(size: size)
            onResizeCode?(size)
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
