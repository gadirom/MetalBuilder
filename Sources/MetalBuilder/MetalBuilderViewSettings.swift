
import SwiftUI
import MetalKit

public struct MetalBuilderViewSettings{
    public init(depthPixelFormat: MTLPixelFormat? = nil,
                clearDepth: Double? = nil,
                stencilPixelFormat: MTLPixelFormat? = nil,
                clearStencil: UInt32? = nil,
                depthStencilAttachmentTextureUsage: MTLTextureUsage? = nil,
                depthStencilStorageMode: MTLStorageMode? = nil,
                clearColor: MTLClearColor? = nil,
                framebufferOnly: Bool? = nil,
                preferredFramesPerSecond: Int? = nil,
                sampleCount: Int? = nil,
                useEDR: Bool = false,
                pixelFormat: MTLPixelFormat? = nil,
                toneMapping: Bool=false) {
        self.depthPixelFormat = depthPixelFormat
        self.stencilPixelFormat = stencilPixelFormat
        self.clearDepth = clearDepth
        self.clearStencil = clearStencil
        self.depthStencilAttachmentTextureUsage = depthStencilAttachmentTextureUsage
        self.depthStencilStorageMode = depthStencilStorageMode
        self.clearColor = clearColor
        self.framebufferOnly = framebufferOnly
        self.preferredFramesPerSecond = preferredFramesPerSecond
        self.sampleCount = sampleCount
        self.useEDR = useEDR
        self.pixelFormat = pixelFormat
        self.toneMapping = toneMapping
    }
    var depthPixelFormat: MTLPixelFormat?
    var clearDepth: Double?
    var stencilPixelFormat: MTLPixelFormat?
    var clearStencil: UInt32?
    
    var depthStencilAttachmentTextureUsage: MTLTextureUsage?
    var depthStencilStorageMode: MTLStorageMode?
    
    var clearColor: MTLClearColor?
    
    var framebufferOnly: Bool?
    var preferredFramesPerSecond: Int?
    
    var sampleCount: Int?
    
    var useEDR: Bool
    
    var pixelFormat: MTLPixelFormat?
    
    var toneMapping: Bool
}

extension MetalBuilderViewSettings{
    func apply(toView view: MTKView) -> MTLPixelFormat?{
        
        if let preferredFramesPerSecond = self.preferredFramesPerSecond{
            view.preferredFramesPerSecond = preferredFramesPerSecond
        }
        
        if let framebufferOnly = self.framebufferOnly{
            view.framebufferOnly = framebufferOnly
        }
       
        if let clearColor = self.clearColor{
            view.clearColor = clearColor
        }
        
        //Depth routine
        if let depthPixelFormat = self.depthPixelFormat{
            view.depthStencilPixelFormat = depthPixelFormat
        }
        if let clearDepth = self.clearDepth{
            view.clearDepth = clearDepth
        }
        //Stencil routine
        if let stencilPixelFormat = self.stencilPixelFormat{
            view.depthStencilPixelFormat = stencilPixelFormat
        }
        if let clearStencil = self.clearStencil{
            view.clearStencil = clearStencil
        }
        if let depthStencilAttachmentTextureUsage = self.depthStencilAttachmentTextureUsage{
            view.depthStencilAttachmentTextureUsage = depthStencilAttachmentTextureUsage
        }
        if #available(iOS 16.0, macOS 13.0, *){
            if let depthStencilStorageMode = self.depthStencilStorageMode{
                view.depthStencilStorageMode = depthStencilStorageMode
            }
        }
        if let sampleCount = self.sampleCount{
            view.sampleCount = sampleCount
        }
        
        return setupEDR(view: view,
                        pixelFormat: pixelFormat,
                        toneMapping: toneMapping
        )
    }
    func setupEDR(view: MTKView,
                  pixelFormat: MTLPixelFormat?,
                  toneMapping: Bool) -> MTLPixelFormat?{
        
        if let l = view.layer as? CAMetalLayer, let sc = l.colorspace{
            if useEDR{
                print("setting EDR")
                l.wantsExtendedDynamicRangeContent = true
                
                let extCS = CGColorSpaceCreateExtendedLinearized(sc)
                //let linearColorSpace = CGColorSpace.extendedLinearDisplayP3
                //let edrMaxLinear = cgcolorcreat
                l.colorspace = extCS
                
                if toneMapping, CAEDRMetadata.isAvailable{
                    print("tone mapping: hlg")
                    l.edrMetadata = .hlg // ??
                }
            }
            
            print("was pixelFormat: \(l.pixelFormat.rawValue)")
            //.bgr10a2Unorm
            if let pixelFormat{
                print("pixelFormat: \(pixelFormat.rawValue)")
                l.pixelFormat = pixelFormat
            }
            
            return l.pixelFormat
        }
        return nil
//        renderData.context.potentialEDRHeadroom = Float(view.window?.screen.potentialEDRHeadroom ?? 1)
    }
}
