import MetalKit

/// Class that is passed to the MetalContent closure and contain useful values.
/// Use these values in CPU code or pass them into shaders.
public final class MetalBuilderRenderingContext{
    /// Viewport size that can be used in a shader
    @MetalState(metalName: "viewportSize") public var viewportSize: simd_uint2 = [0,0]
    /// Scale factor of the view. Used to convert point coordinates into pixel coordinates
    @MetalState(metalName: "scaleFactor") public var scaleFactor: Float = 1
    /// Render time. Starts at zero and pauses when the app is in a background phase
    @MetalState(metalName: "time") public var time: Float = 0
    
    
    weak var timer: MetalBuilderTimer?
    public func pauseTime(){
        timer?.pauseTime()
    }
    public func resumeTime(){
        timer?.resumeTime()
    }
}
