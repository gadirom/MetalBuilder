import MetalKit

/// Structure describing the image to load in a Metal texture.
public struct ImageForTexture{
    let url: URL
    let sRGB: Bool
    //let mipmapsLevel: Int?
    let generateMipmaps: Bool
    let origin: MTKTextureLoader.Origin?
    /// Creates the image descriptor
    /// - Parameters:
    ///   - url: url of an image to load.
    ///   - sRGB: specifies if the image is in sRGB color space.
    ///   - generateMipmaps: if mipmaps should be generated upon load.
    ///   - origin: the is flipped upon load according to this option.
    public init(url: URL,
                sRGB: Bool = true,
                //mipmapsLevel: Int? = nil,
                generateMipmaps: Bool = false,
                origin: MTKTextureLoader.Origin? = nil) {
        self.url = url
        self.sRGB = sRGB
        //self.mipmapsLevel = mipmapsLevel
        self.generateMipmaps = generateMipmaps
        self.origin = origin
    }
}
//calls to MTKTextureLoader
extension ImageForTexture{
    func new2DTexture(options: [MTKTextureLoader.Option: Any], device: MTLDevice) throws -> MTLTexture{
        var options = options
        addOptionsFromSelf(&options)
        let loader = MTKTextureLoader(device: device)
        return try loader.newTexture(URL: url, options: options)
    }
    func newCrossCube(options: [MTKTextureLoader.Option: Any], device: MTLDevice) throws -> MTLTexture{
        var options = options
        addOptionsFromSelf(&options)
        let loader = MTKTextureLoader(device: device)
        return try loader.loadCrossCubeMap(URL: url, options: options)
    }
    func addOptionsFromSelf(_ options:  inout [MTKTextureLoader.Option: Any]){
        options[.SRGB] = sRGB as NSNumber
        options[.generateMipmaps] = generateMipmaps as NSNumber
        if let origin{
            options[.origin] = origin.rawValue
        }
    }
}

//work with MTLTextureContainer
extension ImageForTexture{
    public func loadInto(texture: MTLTextureContainer) throws{
        
        guard let device = texture.device
        else{
            throw MetalBuilderTextureError.noDeviceProvided
        }
        
        let options = texture.descriptor.loaderOptions()
        if texture.descriptor.type == .typeCube{
            texture.texture = try newCrossCube(options: options, device: device)
        }else{
            texture.texture = try new2DTexture(options: options, device: device)
        }
        
        texture.createViewForGrayscaleImage()
    }
}

extension TextureDescriptor{
    func loaderOptions() -> [MTKTextureLoader.Option: Any]{
        var options: [MTKTextureLoader.Option: Any] = [:]
        options[.allocateMipmaps] = (self.mipmapLevelCount > 1) as NSNumber
        options[.textureStorageMode] = self.storageMode.rawValue
        options[.textureUsage] = self.usage.rawValue
        return options
    }
}

extension MTLTextureContainer{
    func createViewForGrayscaleImage(){
        
        var swizzle: MTLTextureSwizzleChannels?
        
        guard let texture
        else{ return }
        
        switch texture.pixelFormat {
        case .r8Unorm, .r16Float, .r32Float,
                .r8Unorm_srgb:
            // Map Red to RGB, set Alpha to 1
            swizzle = MTLTextureSwizzleChannels(red: .red, green: .red, blue: .red, alpha: .one)
            
        case .rg8Unorm, .rg16Float,
                .rg8Unorm_srgb:
            // Common for Grayscale + Alpha. Map Red to RGB, Green to Alpha
            swizzle = MTLTextureSwizzleChannels(red: .red, green: .red, blue: .red, alpha: .green)
            
        default:
            // Return original for standard RGBA textures
            return
        }
        
        // 3. Create a view with the corrected mapping
        if let swizzle,
            let view = texture.makeTextureView(
                pixelFormat: texture.pixelFormat,
                textureType: texture.textureType,
                levels: 0..<texture.mipmapLevelCount,
                slices: 0..<texture.arrayLength,
                swizzle: swizzle
            ){
            
            let t = self.texture
            self.texture = view
            self.sourceTexture = t
            
        }
    }
}


