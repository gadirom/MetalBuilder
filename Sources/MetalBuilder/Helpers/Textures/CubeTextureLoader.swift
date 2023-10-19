import MetalKit

public extension MTKTextureLoader{
    func loadCrossCubeMap(URL: URL,
                          options: [MTKTextureLoader.Option : Any]? = nil) throws -> MTLTexture{
        //create mipmaps for cube, but not for temporary texture
        var options = options
        var mipmapped = false
        var generateMipmaps = false
        var textureUsage = MTLTextureUsage()
        var storageMode = MTLStorageMode.private
        if options != nil{
            if let allocateMipmaps = options![.allocateMipmaps]{
                mipmapped = (allocateMipmaps as! Int)==1
                options![.allocateMipmaps] = nil
            }
            if let genMipmaps = options![.generateMipmaps]{
                generateMipmaps = (genMipmaps as! Int)==1
                options![.generateMipmaps] = nil
            }
            if let texUsage = options![.textureUsage]{
                textureUsage = MTLTextureUsage.init(rawValue: (texUsage as! UInt))
                options![.textureUsage] = MTLTextureUsage.shaderRead.rawValue
            }
            if let strMode = options![.textureStorageMode]{
                storageMode = MTLStorageMode.init(rawValue: strMode as! UInt)!
                options![.textureStorageMode] = MTLStorageMode.private.rawValue
            }
        }
        
        let texture = try self.newTexture(URL: URL, options: options)
        
        let faceSide = texture.height/3
        
        mipmapped = mipmapped || generateMipmaps
        
        let cubeDescriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: texture.pixelFormat, size: faceSide, mipmapped: mipmapped)
    
        cubeDescriptor.usage = textureUsage
        cubeDescriptor.storageMode = storageMode
        
        let cube = self.device.makeTexture(descriptor: cubeDescriptor)
        
        let queue = device.makeCommandQueue()
        let buffer = queue?.makeCommandBuffer()
        
        let blitEncoder = buffer?.makeBlitCommandEncoder()
        
        let faceSize = MTLSize(width: faceSide, height: faceSide, depth: 1)
        
        //Cubemap convention:
        //    +Y
        // -X +Z +X -Z
        //    -Y
        
        let minusX = MTLOrigin(x: 0,          y: faceSide, z: 0)
        let plusZ =  MTLOrigin(x: faceSide,   y: faceSide, z: 0)
        let plusX =  MTLOrigin(x: faceSide*2, y: faceSide, z: 0)
        let minusZ = MTLOrigin(x: faceSide*3, y: faceSide, z: 0)
        
        let plusY = MTLOrigin(x: faceSide, y: 0, z: 0)
        let minusY = MTLOrigin(x: faceSide, y: faceSide*2, z: 0)
        
        //Metal cube slices:
        // +X, -X, +Y, -Y, +Z, -Z.
        
        blit(origin: plusX,  slice: 0)
        blit(origin: minusX, slice: 1)
        blit(origin: plusY,  slice: 2)
        blit(origin: minusY, slice: 3)
        blit(origin: plusZ,  slice: 4)
        blit(origin: minusZ, slice: 5)
        
        func blit(origin: MTLOrigin, slice: Int){
            blitEncoder?.copy(from: texture,
                              sourceSlice: 0,
                              sourceLevel: 0,
                              sourceOrigin: origin,
                              sourceSize: faceSize,
                              
                              to: cube!,
                              destinationSlice: slice,
                              destinationLevel: 0,
                              destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        }
        
        
        if generateMipmaps{
            blitEncoder?.generateMipmaps(for: cube!)
        }
        
        blitEncoder?.endEncoding()
        buffer?.commit()
        buffer?.waitUntilCompleted()
        
        return cube!
        
    }
}
