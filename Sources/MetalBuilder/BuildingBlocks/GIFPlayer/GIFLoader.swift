//
//  GIFLoader.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 21. 11. 2025..
//

import MetalKit

struct GIFLoader: MetalBuildingBlock{
    internal init(context: MetalBuilderRenderingContext,
                  framesTextureArray: MTLTextureContainer,
                  texture: MTLTextureContainer,
                  controller: GIFPlayerController) {
        self.context = context
        self.framesTextureArray = framesTextureArray
        self.texture = texture
        self.controller = controller
        
        self.temporaryArrayOfTextures = .init(
            type: .type2D,
            maxCount: controller.maxAllowedFramesForGIF,
            useHeap: false
        )
    }
    
    
    var context: MetalBuilderRenderingContext
    
    let framesTextureArray: MTLTextureContainer
    
    let texture: MTLTextureContainer
    
    let controller: GIFPlayerController
    
    struct AsyncParameters: MetalBuilder.AsyncParameters{
        
        var url: URL?
        
        nonisolated(unsafe) static var nothing: GIFLoader.AsyncParameters = .init()
        
        mutating func add(_ new: GIFLoader.AsyncParameters?) {
            url = new?.url
        }

    }
    
    nonisolated(unsafe) static var maximumFrames: Int = 1024
    
    private let temporaryArrayOfTextures: ArrayOfTexturesContainer
    
    @MetalState var proceed = false
    
    public var metalContent: MetalContent{
        
        AsyncBlock(context: context,
                   asyncGroupInfo: controller.asyncGroupInfo)
        .asyncContent {
            ManualEncode{ device, _ in
                do{
                    controller.gifIsLoaded = false
                    
                    try load(controller.asyncGroupInfo.parameters.url!,
                             device: device)
                    
                    //i = 0
                    proceed = true
                }catch{
                    print(error)
                    proceed = false
                }
            }
            EncodeGroup(active: $proceed) {
                BlitArrayOfTextures("PopylateFrameTextures")
                    .source(temporaryArrayOfTextures,
                            range: .init{ 0...temporaryArrayOfTextures.textures.count-1 },
                            slice: .constant(0))
                    .destination(framesTextureArray, copyToSlices: true)
            }
        }
        .processResult {
            ManualEncode{device, _ in
                
                temporaryArrayOfTextures.clearAll()
                
                if let textureArray = framesTextureArray.texture{
                    try? self.texture.create(device: device,
                                             size2D: textureArray.size_uint2,
                                             pixelFormat: textureArray.pixelFormat)
                    controller.onLoaded()
                }
            }
        }
    }
    
    func load(_ url: URL, device: MTLDevice) throws{
        
        var frames = try loadGifFrames(url: url)
        
        print("gif frame count: ", frames.count)
        
        if frames.count>controller.maxAllowedFramesForGIF{
            print("gif frame count exceeds maximum allowed frames for GIF: controller.maxAllowedFramesForGIF", frames.count)
            frames.removeLast(frames.count-controller.maxAllowedFramesForGIF)
        }
        
        var options: [MTKTextureLoader.Option: Any] = [:]
        options[.allocateMipmaps] = false as NSNumber
        options[.textureStorageMode] = MTLStorageMode.shared.rawValue
        options[.textureUsage] = MTLTextureUsage.shaderRead.rawValue
        
        let loader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
        
        let textures = try frames.map { frame in
            let tex = try loader.newTexture(cgImage: frame.0, options: options)
            return tex
        }
        
        try prepareTextures(textures: textures, device: device)
        
        //calculate frame times
        controller.frameTiming = .init(frameDurations: frames.map{ $0.1 })
        
    }
    
    func prepareTextures(textures: [MTLTexture], device: MTLDevice) throws{
        
        try temporaryArrayOfTextures.addMTLTexturesWithoutCopying(
            textures: textures
        )
        
        let size: simd_uint2 = [
            UInt32(textures.first!.width),
            UInt32(textures.first!.height)
        ]
        
        try framesTextureArray.create(device: device,
                                      size2D: size,
                                      arrayLength: textures.count,
                                      pixelFormat: textures.first!.pixelFormat)
    }
    
    func loadGifFrames(url: URL) throws -> [(CGImage, TimeInterval)] {
        
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        else {
            throw MetalBuilderGIFPlayerError.couldNotOpenTheFile
        }
        
//        guard let source = CGImageSourceCreateWithData(data as CFData, nil)
//        else { return nil }
        
        let frameCount = CGImageSourceGetCount(source)
        var frames: [(CGImage, TimeInterval)] = []

        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            
            var delayTime = 0.1 // Default delay
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
               let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? TimeInterval {
                    delayTime = unclampedDelay
                } else if let delay = gifProperties[kCGImagePropertyGIFDelayTime as String] as? TimeInterval {
                    delayTime = delay
                }
            }
            frames.append((cgImage, delayTime))
        }
        return frames
    }
}
