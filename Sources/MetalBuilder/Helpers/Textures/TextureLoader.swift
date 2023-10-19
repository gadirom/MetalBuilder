import MetalKit

/// Structure describing the image to load in a Metal texture.
public struct ImageForTexture{
    let url: URL
    let sRGB: Bool
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
                generateMipmaps: Bool = false,
                origin: MTKTextureLoader.Origin? = nil) {
        self.url = url
        self.sRGB = sRGB
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
        let options = texture.descriptor.loaderOptions()
        if texture.descriptor.type == .typeCube{
            texture.texture = try newCrossCube(options: options, device: texture.device!)
        }else{
            texture.texture = try new2DTexture(options: options, device: texture.device!)
        }
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


