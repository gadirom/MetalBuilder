import MetalKit
import OrderedCollections

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
    var dict: OrderedDictionary<String, (FieldStyle, String, Int, Bool)>{ get }
    subscript(key: String, index: Int) -> any BinaryFloatingPoint { get set }
}
public extension MetalStruct{
    var dict: OrderedDictionary<String, (FieldStyle, String, Int, Bool)>{
        [:]
    }
    subscript(key: String, index: Int) -> any BinaryFloatingPoint {
        get{ 0 }
        set{     }
    }
//    static var storedState: StoredMetalState<Self>{
//        StoredMetalState(wrappedValue: Self.init())
//    }
}
