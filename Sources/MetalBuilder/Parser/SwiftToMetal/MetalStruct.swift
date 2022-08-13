import MetalKit

///Make a struct conform to this protocol if you want it to be automatically declared in Metal library source
///when using this type for buffer and bytes arguments in Metal functions
///
///Swift types allowed:
///SIMDN<type>,  2<N<4, type - any key from swiftTypesToMetalTypes dictionary
///For the scalar type use Float
///
///Unfortunately, there is no native way of differing between scalar Swift types at runtime,
///hence only one scalar type is allowed: Float
public protocol MetalStruct{
    init()
}
