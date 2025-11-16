
import SwiftUI
import MetalKit

public struct EDRSettings{
    public init(useEDR: Bool = false,
                  pixelFormat: MTLPixelFormat = .rgba16Float,
                  toneMapping: Bool = false,
                  colorSpace: CGColorSpace = .init(name: CGColorSpace.displayP3)!) {
        self.useEDR = useEDR
        self.pixelFormat = pixelFormat
        self.toneMapping = toneMapping
        self.colorSpace = colorSpace
    }
    
    public init(){}
    public var useEDR: Bool = false
    public var pixelFormat: MTLPixelFormat? = .rgba16Float
    public var toneMapping: Bool = false
    public var colorSpace: CGColorSpace? = .init(name: CGColorSpace.displayP3)!
}

@MainActor
public class MetalBuilderViewSettings{
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
                edrSettings: EDRSettings = .init()) {
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
        
        self.edr = edrSettings
        
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
    
    var edrSettingsChanged = false
    
    public var edr: EDRSettings{
        didSet{
            edrSettingsChanged = true
        }
    }
}

extension MetalBuilderViewSettings{
    func apply(toView view: MTKView) -> MTLPixelFormat{
        
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
        
        return setupEDR(view: view)
    }
    func setupEDR(view: MTKView) -> MTLPixelFormat{
        
        let l = view.layer as! CAMetalLayer
        let sc = l.colorspace
        
        //if edr.useEDR{
        print("setting EDR: \(edr.useEDR)")
            l.wantsExtendedDynamicRangeContent = edr.useEDR
            
            //let extCS = CGColorSpaceCreateExtendedLinearized(sc)
            //let linearColorSpace = CGColorSpace.extendedLinearDisplayP3
            //let edrMaxLinear = cgcolorcreat
            
            //let colorSpace = CGColorSpace.
        print("was colorSpace: \(l.colorspace)")
        if let colorSpace = edr.colorSpace{
            l.colorspace = edr.colorSpace //.init(name: CGColorSpace.sRGB)!
            print("colorSpace changed to: \(l.colorspace)")
        }
            
            if edr.toneMapping, CAEDRMetadata.isAvailable{
                print("tone mapping: hlg")
                l.edrMetadata = .hlg // ??
            }else{
                print("tone mapping: none")
                l.edrMetadata = .none
            }
        //}
        
        print("was pixelFormat: \(l.pixelFormat.rawValue)")
        //.bgr10a2Unorm
        //if let pixelFormat = edrSettings.pixelFormat{
        
        if let pixelFormat = edr.pixelFormat{
            l.pixelFormat = pixelFormat
            print("changed to pixelFormat: \(l.pixelFormat.rawValue)")
        }
        //}
        
        return l.pixelFormat
//        renderData.context.potentialEDRHeadroom = Float(view.window?.screen.potentialEDRHeadroom ?? 1)
    }
}
