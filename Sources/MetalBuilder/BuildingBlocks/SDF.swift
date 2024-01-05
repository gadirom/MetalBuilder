import MetalPerformanceShaders

extension MTLSize: Equatable{
    public static func == (lhs: MTLSize, rhs: MTLSize) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height && lhs.depth == rhs.depth
    }
}

public struct SDF: MetalBuildingBlock{
    public init(context: MetalBuilderRenderingContext,
                monoTexture: MTLTextureContainer,
                sdf: MTLTextureContainer,
                normalization: MetalBinding<Float> = .constant(1),
                invert: MetalBinding<Bool> = .constant(false)) {
        self.context = context
        self.monoTexture = monoTexture
        self.sdf = sdf
        self._normalization = normalization
        self._invert = invert
    }
    
    public var context: MetalBuilderRenderingContext
    public var helpers: String = ""
    public var librarySource: String = ""
    
    public var compileOptions: MetalBuilderCompileOptions? = nil
    
    let monoTexture: MTLTextureContainer
    let sdf: MTLTextureContainer
    
    @MetalBinding var normalization: Float
    @MetalBinding var invert: Bool
    
    @MetalState(metalName: "inverter") var inverter: Float = 1
    
    @MetalTexture(
        TextureDescriptor()
        .manual()) var sdfInvertedTexture
    
    public var metalContent: MetalContent{
        
        ManualEncode{device, passInfo in
            inverter = invert ? -1 : 1
            if sdfInvertedTexture.texture?.mtlSize != sdf.texture?.mtlSize{
                try! sdfInvertedTexture.create(device: device,
                                               mtlSize: sdf.texture!.mtlSize,
                                               pixelFormat: monoTexture.texture!.pixelFormat)
            }
        }
        
        MPSUnary {
            MPSImageEuclideanDistanceTransform(device: $0)
        }
            .source(monoTexture)
            .destination(sdf)
        Compute("inflatorInvertMono")
            .texture(monoTexture, argument: .init(type: "float", access: "read_write", name: "in"), fitThreads: true)
            .body(
        """
            float alpha = 1.-in.read(gid).r;
            in.write(float4(alpha), gid);
        """
            )
        MPSUnary {
            MPSImageEuclideanDistanceTransform(device: $0)
        }
        .source(monoTexture)
        .destination(sdfInvertedTexture)
        Compute("inflatorJoinSDF")
            .texture(sdf, argument: .init(type: "float", access: "read_write", name: "out"))
            .texture(sdfInvertedTexture, argument: .init(type: "float", access: "read", name: "in"), fitThreads: true)
            .bytes($normalization, name: "normalization")
            .bytes($inverter)
            .body(
            """
                float d = in.read(gid).r - out.read(gid).r;
                float sdfSizeX = float(gidCount.x);
                d /= normalization;//normalizeing d
                d *= inverter;
                out.write(float4(d,0,0,0), gid);
            
            """
            )
    }
}
