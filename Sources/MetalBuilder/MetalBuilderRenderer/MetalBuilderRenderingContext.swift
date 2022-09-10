import MetalKit

public final class MetalBuilderRenderingContext{
    @MetalState(metalName: "viewportSize") public var viewportSize: simd_uint2 = [0,0]
    @MetalState(metalName: "scaleFactor") public var scaleFactor: Float = 1
}
