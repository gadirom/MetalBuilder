
@resultBuilder
public enum MetalResultBuilder{
    public static func buildBlock(_ components: MetalBuilderComponent...) -> MetalBuilderResult{
        components
    }
}

public typealias MetalBuilderResult = [MetalBuilderComponent]

enum MetalBuilderResultBuilderError: Error {
case bufferArgumentError(String), textureArgumentError(String)
}
