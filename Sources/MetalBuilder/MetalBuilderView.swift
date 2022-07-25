
import MetalKit
import SwiftUI

public struct MetalBuilderView: UIViewRepresentable {
    
    public let librarySource: String
    @Binding public var isDrawing: Bool
    @MetalResultBuilder public let metalContent: (Binding<simd_uint2>)->MetalBuilderResult
    let onResizeCode: ((CGSize)->())?
    
    public init(librarySource: String,
                isDrawing: Binding<Bool>,
                @MetalResultBuilder metalContent: @escaping (Binding<simd_uint2>) -> MetalBuilderResult) {
        self.init(librarySource: librarySource,
                  isDrawing: isDrawing,
                  metalContent: metalContent,
                  onResizeCode: nil)
    }
    init(librarySource: String,
         isDrawing: Binding<Bool>,
         @MetalResultBuilder metalContent: @escaping (Binding<simd_uint2>) -> MetalBuilderResult,
         onResizeCode: ((CGSize)->())?) {
        self.librarySource = librarySource
        self._isDrawing = isDrawing
        self.metalContent = metalContent
        self.onResizeCode = onResizeCode
    }
    
    public func onResize(perform: @escaping (CGSize)->())->MetalBuilderView{
        MetalBuilderView(librarySource: librarySource,
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
        //mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        
        context.coordinator.setupRenderer(librarySource: librarySource,
                                          pixelFormat: mtkView.colorPixelFormat,
                                          metalContent: metalContent)
        
        return mtkView
    }
    public func updateUIView(_ uiView: UIView, context: Context){
        context.coordinator.isDrawing = isDrawing
        context.coordinator.onResizeCode = onResizeCode
    }
    public class Coordinator: NSObject, MTKViewDelegate {
        
        var device: MTLDevice!
        var renderer: MetalBuilderRenderer?
        
        var isDrawing = false
        var onResizeCode: ((CGSize)->())?
        
        override init(){
            super.init()
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.device = metalDevice
            }
        }
        
        func setupRenderer(librarySource: String, pixelFormat: MTLPixelFormat, metalContent: (Binding<simd_uint2>)->MetalBuilderResult){
            do{
                renderer =
                try MetalBuilderRenderer(device: device,
                                         librarySource: librarySource,
                                         pixelFormat: pixelFormat,
                                         metalContent: metalContent)
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
            do {
                try renderer?.draw(drawable: drawable)
            } catch { print(error) }
        }
    }
}
