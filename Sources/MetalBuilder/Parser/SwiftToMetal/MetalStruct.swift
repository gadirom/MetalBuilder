import MetalKit
import OrderedCollections

///Make a struct conform to this protocol if you want it to be automatically declared in Metal library source
///when using this type for buffer and bytes arguments in Metal functions
///
public protocol MetalStruct{
    init()
    var dict: MetalStructDictType{ get }
    subscript(key: String, index: Int) -> any BinaryFloatingPoint { get set }
    
    func filterKeys(_ key: String) -> Bool
    var uiRefreshers: [String]{ get }
}
public extension MetalStruct{
    var dict: OrderedDictionary<String, (FieldStyle, String, Int, Bool)>{
        [:]
    }
    subscript(key: String, index: Int) -> any BinaryFloatingPoint {
        get{ 0 }
        set{   }
    }
    func filterKeys(_ key: String) -> Bool{
        true
    }
    var uiRefreshers: [String]{
        []
    }
//    static var storedState: StoredMetalState<Self>{
//        StoredMetalState(wrappedValue: Self.init())
//    }
}

public typealias MetalStructDictType = OrderedDictionary<String, (FieldStyle, String, Int, Bool)>
