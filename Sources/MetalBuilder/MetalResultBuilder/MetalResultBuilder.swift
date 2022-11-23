import SwiftUI
import MetalKit

@resultBuilder
public enum MetalResultBuilder{
    public static func buildBlock(_ components: MetalBuilderComponent...) -> MetalContent{
        components
    }
}

public typealias MetalContent = [MetalBuilderComponent]

public typealias MetalBuilderContent = (MetalBuilderRenderingContext) -> MetalContent
