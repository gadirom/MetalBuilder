
import SwiftUI
import MetalKit

@propertyWrapper
public final class MetalTexture{
    public var wrappedValue: MTLTextureContainer
    
    public var projectedValue: MetalTexture{
        self
    }
    
    public init(wrappedValue: MTLTextureContainer){
        self.wrappedValue = wrappedValue
    }
    
    public init(_ descriptor: TextureDescriptor=TextureDescriptor().manual(),
                label: String?=nil,
                fromImage: ImageForTexture? = nil){
        self.wrappedValue = MTLTextureContainer(descriptor,
                                                label: label,
                                                fromImage: fromImage)
    }
}

enum MetalBuilderTextureError: Error {
case textureNotCreated, noDescriptor, descriptorSizeContainsZero,
    pixelFormatFromDrawable, noDeviceProvided
}

public final class MTLTextureContainer{
    public var descriptor: TextureDescriptor
    public var label: String?
    public var texture: MTLTexture?{
        didSet{
            updateResourceInArgumentBuffers()
        }
    }
    var image: ImageForTexture?
    weak var device: MTLDevice?
    internal var argBufferInfo = ArgBufferInfo()
    internal var dataType: MTLDataType = .texture
    
    init(){
        descriptor = TextureDescriptor()
    }
    
    public init(_ descriptor: TextureDescriptor, label: String?=nil, fromImage: ImageForTexture? = nil){
        self.descriptor = descriptor
        self.image = fromImage
        self.label = label
    }
    
    //creates or loads the texture
    public func initialize(device: MTLDevice,
                    viewportSize: simd_uint2,
                    pixelFormat: MTLPixelFormat?=nil) throws{
        self.device = device
        if texture != nil{//texture already initialized!
            return
        }
        if !descriptor.manualCreation{
            if let image{
                try loadImage(image)
            }else{
                try create(device: device,
                           viewportSize: viewportSize,
                           pixelFormat: pixelFormat)
            }
        }
    }
    
    public func createLike(size: simd_uint2, device: any MTLDevice) throws{
        guard self.texture?.size_uint2 != size,
              size.x>0, size.y>0
        else{ return }
        try create(device: device, size2D: size)
    }
    
    public func create(device: MTLDevice, drawable: CAMetalDrawable?=nil, newDescriptor: TextureDescriptor?=nil) throws{
        if let desc = newDescriptor{
            self.descriptor = desc
        }
        if let drawable{
            try create(device: device,
                       viewportSize: simd_uint2(x: UInt32(drawable.texture.width),
                                                y: UInt32(drawable.texture.height)),
                       pixelFormat: drawable.texture.pixelFormat)
        }else{
            try create(device: device,
                       viewportSize: simd_uint2(x: 1,
                                                y: 1),
                       pixelFormat: .rgba8Unorm)
        }
    }
    
    public func create(device: MTLDevice, size2D: simd_uint2, arrayLength: Int=1, pixelFormat: MTLPixelFormat?=nil) throws{
        try create(device: device,
                   mtlSize: .init(width: Int(size2D.x), height: Int(size2D.y), depth: 1),
                   arrayLength: arrayLength,
                   pixelFormat: pixelFormat)
    }
    
    //pixel format should not be from drawable
    public func create(device: MTLDevice, mtlSize: MTLSize, arrayLength: Int=1, pixelFormat: MTLPixelFormat?=nil) throws{
        self.descriptor.arrayLength = arrayLength
        self.descriptor.size = .fixed(mtlSize)
        if let pixelFormat{
            self.descriptor.pixelFormat = .fixed(pixelFormat)
        }else{
            if case .fromDrawable = self.descriptor.pixelFormat{
                throw MetalBuilderTextureError
                    .pixelFormatFromDrawable
            }
        }
        try create(device: device,
                   viewportSize: [0,0],
                   pixelFormat: .invalid)
    }
    
    func create(device: MTLDevice,
                viewportSize: simd_uint2,
                pixelFormat: MTLPixelFormat?) throws{
        //self.device = device
        guard let mtlDescriptor = descriptor.mtlTextureDescriptor(viewportSize: viewportSize, drawablePixelFormat: pixelFormat)
        else{
            throw MetalBuilderTextureError
                .noDescriptor
        }
        guard mtlDescriptor.width>0 && mtlDescriptor.height>0
        else{
            throw MetalBuilderTextureError
                .descriptorSizeContainsZero
        }
        mtlDescriptor.allowGPUOptimizedContents = true
        
        guard let texture = device.makeTexture(descriptor: mtlDescriptor)
        else{
            throw MetalBuilderTextureError
                .textureNotCreated
        }
        if let label{
            texture.label = label
        }
        self.texture = texture
    }
}

extension MTLTextureContainer: Equatable{
    public static func == (lhs: MTLTextureContainer, rhs: MTLTextureContainer) -> Bool {
        lhs === rhs
    }
}

extension MTLTextureContainer: MTLResourceContainer{
    var mtlResource: MTLResource{
        texture!
    }
    func updateResource(argBuffer: ArgumentBuffer, id: Int, offset: Int){
        argBuffer.encoder!.setTexture(self.texture, index: id)
        print("updated texture resource [\(id)] in \(argBuffer.name)")
    }
}

//load image
public extension MTLTextureContainer{
    func loadImage(device: MTLDevice?=nil, _ image: ImageForTexture, newDescriptor: TextureDescriptor? = nil) throws{
        if let newDescriptor{
            self.descriptor = newDescriptor
        }
        if let device{
            self.device = device
        }
        try image.loadInto(texture: self)
    }
}

//load and store data
public extension MTLTextureContainer{
    func getData<T:SIMD >(type: T.Type, region: MTLRegion?=nil)->Data?{
        guard let texture
        else{ return nil }
        
        var region = region
        if region == nil{
            region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                               size: MTLSize(width: texture.width,
                                             height: texture.height, depth: texture.depth))
        }
        let bytesPerRow = MemoryLayout<T>.size * region!.size.width
        let bytesPerImage = bytesPerRow*region!.size.height * region!.size.depth
        var array = [T](repeating: T.init(), count: bytesPerImage)
        array.withUnsafeMutableBytes{ bts in
            texture.getBytes(bts.baseAddress!,
                             bytesPerRow: bytesPerRow,
                             from: region!,
                             mipmapLevel: 0)
        }
        let data = Data(bytes: &array, count: bytesPerImage)
        return data
    }
    func load<T>(data: Data, type: T.Type, region: MTLRegion? = nil){
        var region = region
        if region == nil{
            region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                               size: MTLSize(width: texture!.width,
                                             height: texture!.height, depth: texture!.depth))
        }
        let bytesPerRow = MemoryLayout<T>.size * region!.size.width
        data.withUnsafeBytes{ bts in
            texture!.replace(region: region!, mipmapLevel: 0,
                             withBytes: bts.baseAddress!, bytesPerRow: bytesPerRow)
        }
    }
}

public enum TextureSize{
    case fixed(MTLSize), fromViewport(simd_double2)
}

public enum TexturePixelFormat{
case fixed(MTLPixelFormat), fromDrawable
}

public struct TextureDescriptor{
    public var size: TextureSize? = nil
    public var pixelFormat: TexturePixelFormat? = nil
    
    public var type: MTLTextureType = .type2D
    public var arrayLength: Int = 1
    public var usage: MTLTextureUsage = [.shaderRead, .shaderWrite, .renderTarget]
    
    public var storageMode: MTLStorageMode = .private
    
    public var mipmapLevelCount: Int = 1 // if below zero calculate max levels
    
    public var sampleCount: Int = 1
    
    var manualCreation = false
    
    public init() {}
    
    mutating public func mtlTextureDescriptor(viewportSize: simd_uint2 = [0,0],
                                              drawablePixelFormat: MTLPixelFormat? = nil)->MTLTextureDescriptor?{
        
        let d = MTLTextureDescriptor()
    
        d.textureType = type
        d.arrayLength = arrayLength
        d.usage = usage
        d.storageMode = storageMode
        d.sampleCount = sampleCount
        
        //Determine size
        var s: MTLSize?
        if size == nil{ size = .fromViewport(.init(x: 1, y: 1)) }
        switch size! {
        case .fixed(let size): s = size
        case .fromViewport(let scale):
            s = MTLSize(width: Int(Double(viewportSize.x)*scale.x),
                        height: Int(Double(viewportSize.y)*scale.y),
                        depth: 1)
        }
        guard let size = s
        else{ return nil }
        d.width = size.width
        d.height = size.height
        d.depth = size.depth
        
        //Determine PixelFormat
        var pf: MTLPixelFormat
        if pixelFormat == nil{ pixelFormat = .fromDrawable }
        switch pixelFormat!{
        case .fixed(let format): pf = format
        case .fromDrawable:
            guard let drawablePixelFormat = drawablePixelFormat
            else { return nil }
            pf = drawablePixelFormat
        }
        d.pixelFormat = pf
        
        d.mipmapLevelCount = mipmapLevelCount<0 ? calculateMaxMipmapLevels(
            width: size.width, height: size.height) : mipmapLevelCount
        
        return d
    }
}
public extension TextureDescriptor{
    func type(_ type: MTLTextureType) -> TextureDescriptor {
        var d = self
        d.type = type
        return d
    }
    func sampleCount(_ n: Int) -> TextureDescriptor {
        var d = self
        d.sampleCount = n
        return d
    }
    func arrayLength(_ n: Int) -> TextureDescriptor {
        var d = self
        d.arrayLength = n
        return d
    }
    func usage(_ usage: MTLTextureUsage) -> TextureDescriptor {
        var d = self
        d.usage = usage
        return d
    }
    func pixelFormat(_ pixelFormat: MTLPixelFormat) -> TextureDescriptor {
        var d = self
        d.pixelFormat = .fixed(pixelFormat)
        return d
    }
    func pixelFormatFromDrawable() -> TextureDescriptor {
        var d = self
        d.pixelFormat = .fromDrawable
        return d
    }
    func fixedSize(_ squareSize: Int) -> TextureDescriptor {
        var d = self
        let mtlSize = MTLSize(width: squareSize, height: squareSize, depth: 1)
        d = fixedSize(mtlSize)
        return d
    }
    func fixedSize(_ size: CGSize) -> TextureDescriptor {
        var d = self
        let mtlSize = MTLSize(width: Int(size.width), height: Int(size.height), depth: 1)
        d = fixedSize(mtlSize)
        return d
    }
    func fixedSize(_ size: (Int, Int)) -> TextureDescriptor {
        var d = self
        let mtlSize = MTLSize(width: size.0, height: size.1, depth: 1)
        d = fixedSize(mtlSize)
        return d
    }
    func fixedSize(_ size: simd_uint2) -> TextureDescriptor {
        var d = self
        let mtlSize = MTLSize(width: size.0, height: size.1, depth: 1)
        d = fixedSize(mtlSize)
        return d
    }
    func fixedSize(_ mtlSize: MTLSize) -> TextureDescriptor {
        var d = self
        d.size = .fixed(mtlSize)
        return d
    }
    func sizeFromViewport(scaled: simd_double2) -> TextureDescriptor {
        var d = self
        d.size = .fromViewport(scaled)
        return d
    }
    func sizeFromViewport(scaled: Double = 1) -> TextureDescriptor {
        var d = self
        d.size = .fromViewport(.init(x: scaled, y: scaled))
        return d
    }
    func storageMode(_ storageMode: MTLStorageMode) -> TextureDescriptor {
        var d = self
        d.storageMode = storageMode
        return d
    }
    func mipmaps(_ mipmapLevelCount: Int) -> TextureDescriptor {
        var d = self
        d.mipmapLevelCount = mipmapLevelCount
        return d
    }
    func mipmapsAll() -> TextureDescriptor {
        var d = self
        d.mipmapLevelCount = -1
        return d
    }
    func manual() -> TextureDescriptor {
        var d = self
        d.manualCreation = true
        return d
    }
}

public func mipmapDimension(_ level: Int, baseWidth: Int, baseHeight: Int) -> (width: Int, height: Int) {

    // Calculate the width and height for the given level
    let width = max(baseWidth >> level, 1)  // Right shift to halve the size for each level
    let height = max(baseHeight >> level, 1)  // Right shift to halve the size for each level
    
    return (width, height)
}

public extension MTLTexture{
    func mipmapDimension(_ level: Int) -> (width: Int, height: Int){
        MetalBuilder.mipmapDimension(level, baseWidth: width, baseHeight: height)
    }
    var size2D: (Int, Int){
        (width, height)
    }
    var size_uint2: simd_uint2{
        [UInt32(width), UInt32(height)]
    }
    var mtlSize: MTLSize{
        .init(width: width, height: height, depth: depth)
    }
}


func calculateMaxMipmapLevels(width: Int, height: Int) -> Int{

    let heightLevels = ceil(log2(Double(height)))
    let widthLevels = ceil(log2(Double(width)))
    let mipCount = (heightLevels > widthLevels) ? heightLevels : widthLevels

    return Int(mipCount)
}
