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

    template <typename T>
    struct remove_address_space
    {
      typedef T type;
    };

    template <typename T>
    struct remove_address_space<device T>
    {
      typedef T type;
    };
    template <typename T>
    struct remove_address_space<constant T>
    {
      typedef T type;
    };

    #define remove_address_space_and_reference(X) remove_address_space<metal::remove_reference_t<decltype( *X )>>::type

"""
