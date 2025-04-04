
import MetalKit
import SwiftUI
import OrderedCollections

typealias ValueBinding = (get: (Int)->(any BinaryFloatingPoint),
                          set: (Int, any BinaryFloatingPoint)->(),
                          defaultValue: (Int)->(any BinaryFloatingPoint),
                          integer: Bool)

public final class StoredMetalState<T: MetalStruct>{
    public var state: T
    public var binding: MetalBinding<T>{
        MetalBinding<T>(
            get: { self.state },
            set: { self.state = $0 },
            metalType: metalType,
            metalName: metalName)
    }
    public var `self`: StoredMetalState<T>{
        self
    }
    var metalType: String?
    var metalName: String?
    
    var containerName: String
    var saveToDefaults: Bool
    
    var onChange: (()->())?
    
    func valueBinding(_ key: String) -> ValueBinding{
        (
            get: { self.state[key, $0] },
            set: {
                self.state[key, $0] = $1
                self.onChange?()
                self.saveToDefaults(index: $0, key: key, value: $1)
            },
            defaultValue: { self.defaultValue(key: key, index: $0) },
            integer: self.state.dict[key]!.3
        )
    }
    
    func defaultValue(key: String, index: Int)->(any BinaryFloatingPoint){
        T()[key, index]
    }
   
    public init(state: T?=nil,
                metalType: String?=nil,
                metalName: String?=nil,
                onChange: (()->())?=nil,
                storeInDefaults: Bool = true,
                containerName: String?=nil){
        self.state = state ?? T()
        self.metalType = metalType
        self.metalName = metalName
        
        self.onChange = onChange
        self.saveToDefaults = storeInDefaults
        self.containerName = containerName ?? StoredMetalState<T>.containerNameFromType
        
        if storeInDefaults{
            loadFomDefaults()
        }
    }
}

private extension StoredMetalState{
    static private var containerNameFromType: String{
        let mirror = Mirror(reflecting: T())
        return String(describing: mirror.subjectType)
    }
}

//Saving to and loading from User Defaults
public extension StoredMetalState{
    /// Loads uniforms values from User Defaults.
    ///
    /// If no value of an apropriate type is found for the key in User Defaults, the initial value is used.
    func loadFomDefaults(){
        print("Loading struct \(containerName) values from User Defaults...")
        //print(UserDefaults.standard.dictionaryRepresentation().keys)
        
        for p in state.dict{
            for i in 0..<p.value.2{
                let defaultsKey = userDefaultsKeyForFieldKey(p.key, index: i)
                if let value = UserDefaults.standard.object(forKey: defaultsKey){
                    
                    if let value = value as? Double{
                        print("Loaded: ", p.key , value)
                        state[p.key, i] = value
                    }else{
                        state[p.key, i] = defaultValue(key: p.key, index: i)
                    }
                }
            }
        }
    }
    /// Saves a uniform value to User Defaults.
    /// - Parameters:
    ///   - index: index of the value in the field
    ///   - key: Key for the struct field.
    ///   - value: value to save
    func saveToDefaults(index: Int, key: String, value: any BinaryFloatingPoint){
        guard saveToDefaults
        else{ return }
        let defaultsKey = userDefaultsKeyForFieldKey(key, index: index)
        print("Saving to User Defaults: \(defaultsKey), \(value)")
        UserDefaults.standard.set(Double(value), forKey: defaultsKey)
    }
    /// Returns the key that is used to store and retrive the value from User Defaults.
    /// - Parameter name: Field key.
    /// - Parameter index: Index of the value (e.g. `2` for `y` in `simd_float3`).
    /// - Returns: key in User Defaults storage.
    func userDefaultsKeyForFieldKey(_ fieldKey: String, index: Int)->String{
        "\(prefixForDefaults)-\(containerName)-\(fieldKey)-\(index)"
    }
    /// Returns the name of a uniform value for the key that is used to store and retrive that value from User Defaults.
    /// - Parameter key: The key in User Defaults storage.
    /// - Returns: Uniforms value name.
//    func uniformsKeyForUserDefaultsKey(_ key: String)->String?{
//        if let range = key.range(of: prefixForDefaults){
//            return String(key[range.upperBound...])
//        }else{ return nil }
//    }
    var prefixForDefaults: String{
        "MetalStruct"
    }
    ///Clears the User Defaults storage.
    ///
    ///Attention! All other stored values will also be erased!
    func clearDefaults(){
        print("Clearing Defaults for Uniforms")
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
}
