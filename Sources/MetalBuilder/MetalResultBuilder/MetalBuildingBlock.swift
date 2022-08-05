import SwiftUI

/// Protocol for declaring autonomous building blocks
///
/// if compileOptions are not nil the source will compile into separate library
public protocol MetalBuildingBlock: MetalBuilderComponent{
    var context: MetalBuilderRenderingContext { get set }
    var librarySource: String { get }
    var compileOptions: MetalBuilderCompileOptions? { get }
    @MetalResultBuilder var metalContent: MetalContent{ get }
}

