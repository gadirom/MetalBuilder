import MetalKit

public struct MetalBuilderCompileOptions{
    
    let mtlCompileOptions: MTLCompileOptions?
    let libraryPrefix: MetalBuilderLibraryPrefix
    
    public static let `default` = MetalBuilderCompileOptions(mtlCompileOptions: nil, libraryPrefix: .default)
    
    
    public init(mtlCompileOptions: MTLCompileOptions?, libraryPrefix: MetalBuilderLibraryPrefix) {
        self.mtlCompileOptions = mtlCompileOptions
        self.libraryPrefix = libraryPrefix
    }
}
    
public enum MetalBuilderLibraryPrefix{
    case `default`, custom(String)
}

public let kMetalBuilderDefaultLibraryPrefix = """
    #include <metal_stdlib>

    using namespace metal;
"""
