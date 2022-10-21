import MetalKit
import SwiftUI
import OrderedCollections

public final class UniformsContainer: ObservableObject{
    
    @Published var bufferAllocated = false
    
    var dict: OrderedDictionary<String, Property>
    var mtlBuffer: MTLBuffer!
    var pointer: UnsafeRawPointer?
    var metalDeclaration: MetalTypeDeclaration
    var metalType: String?
    var metalName: String?
    let length: Int
    let saveToDefaults: Bool
    
    var pointerBinding: Binding<UnsafeRawPointer?>{
        Binding<UnsafeRawPointer?>(
            get: { self.pointer }, set: { _ in })
    }
    
    internal init(dict: OrderedDictionary<String, Property>,
                  mtlBuffer: MTLBuffer? = nil,
                  pointer: UnsafeRawPointer? = nil,
                  metalDeclaration: MetalTypeDeclaration,
                  metalType: String? = nil,
                  metalName: String? = nil,
                  length: Int,
                  saveToDefaults: Bool) {
        self.dict = dict
        self.mtlBuffer = mtlBuffer
        self.pointer = pointer
        self.metalDeclaration = metalDeclaration
        self.metalName = metalName
        self.length = length
        self.saveToDefaults = saveToDefaults
    }
}
//init and setup
public extension UniformsContainer{
    convenience init(_ u: UniformsDescriptor,
         type: String? = nil,
         name: String? = nil,
         saveToDefaults: Bool = true){
        var dict = u.dict
        var offset = 0
        var metalType: String
        if let type = type{
            metalType = type
        }else{
            metalType = "Uniforms"
        }
        var declaration = "struct " + metalType
        declaration += "{\n"
        for t in u.dict{
            let metalType = uniformsTypesToMetalTypes[t.value.type]!
            var property = t.value
            property.offset = offset
            dict[t.key] = property
            offset += metalType.length
            declaration += "   "
            declaration += metalType.string + " " + t.key + ";\n"
        }
        declaration += "};\n"
        
        let metalDeclaration = MetalTypeDeclaration(typeName: metalType,
                                                    declaration: declaration)

        self.init(dict: dict,
                  metalDeclaration: metalDeclaration,
                  metalName: name,
                  length: offset,
                  saveToDefaults: saveToDefaults)
    }
    
    /// Setups Uniforms Container before rendering
    /// - Parameter device: MTLDevice
    func setup(device: MTLDevice){
        if pointer == nil{
            var bytes = dict.values.flatMap{ $0.initValue }
            mtlBuffer = device.makeBuffer(bytes: &bytes, length: length)
            pointer = UnsafeRawPointer(mtlBuffer.contents())
            bufferAllocated = true
        }
    }
}
 
//Modify and get state of properties with this functions
public extension UniformsContainer{
    func setFloat(_ value: Float, for key: String){
        guard let property = dict[key]
        else{ return }
        mtlBuffer.contents().advanced(by: property.offset).bindMemory(to: Float.self, capacity: 1).pointee = value
    }
    func setFloat2(_ array: [Float], for key: String){
        setFloat2(simd_float2(array), for: key)
    }
    func setFloat2(_ value: simd_float2, for key: String){
        guard let property = dict[key]
        else{ return }
        mtlBuffer.contents().advanced(by: property.offset).bindMemory(to: simd_float2.self, capacity: 1).pointee = value
    }
    func setFloat3(_ array: [Float], for key: String){
        setFloat3(simd_float3(array), for: key)
    }
    func setFloat3(_ value: simd_float3, for key: String){
        guard let property = dict[key]
        else{ return }
        mtlBuffer.contents().advanced(by: property.offset).bindMemory(to: simd_float3.self, capacity: 1).pointee = value
    }
    func setFloat4(_ array: [Float], for key: String){
        setFloat4(simd_float4(array), for: key)
    }
    func setFloat4(_ value: simd_float4, for key: String){
        guard let property = dict[key]
        else{ return }
        mtlBuffer.contents().advanced(by: property.offset).bindMemory(to: simd_float4.self, capacity: 1).pointee = value
    }
    func setSize(_ size: CGSize, for key: String){
        setFloat2([Float(size.width), Float(size.height)], for: key)
    }
    func setPoint(_ point: CGPoint, for key: String){
        setFloat2([Float(point.x), Float(point.y)], for: key)
    }
    func setRGBA(_ color: Color, for key: String){
        if let c = UIColor(color).cgColor.components{
            setFloat4(c.map{ Float($0) }, for: key)
        }
    }
    func setRGB(_ color: Color, for key: String){
        if let c = UIColor(color).cgColor.components{
            setFloat3(c.map{ Float($0)}, for: key)
        }
    }
    func setArray(_ value: [Float], for key: String){
        if let property = dict[key]{
            switch property.type{
            case .float:
                setFloat(value[0], for: key)
            case .float2:
                if value.count == 2{
                    setFloat2(value, for: key)
                }
            case .float3:
                if value.count == 3{
                    setFloat3(value, for: key)
                }
            case .float4:
                if value.count == 4{
                    setFloat4(value, for: key)
                }
            }
        }
    }
    func getFloat(_ key: String)->Float?{
        guard let property = dict[key]
        else{ return nil }
        return mtlBuffer.contents().advanced(by: property.offset).bindMemory(to: Float.self, capacity: 1).pointee
    }
}
//import and export Uniforms
extension UniformsContainer{
    ///Returns uniforms encoded into json
    var json: Data?{
        var dictToEncode: [String: Encodable] = [:]
        for p in dict{
            let type = p.value.type
            let pointer = self.pointer!.advanced(by: p.value.offset)
            let value: Encodable
            switch type{
            case .float: value = pointer.bindMemory(to: Float.self, capacity: 1).pointee
            case .float2: let v = pointer.bindMemory(to: simd_float2.self, capacity: 1).pointee
                value = v.indices.map({v[$0]})
            case .float3: let v = pointer.bindMemory(to: simd_float3.self, capacity: 1).pointee
                value = v.indices.map({v[$0]})
            case .float4: let v = pointer.bindMemory(to: simd_float4.self, capacity: 1).pointee
                value = v.indices.map({v[$0]})
            }
            dictToEncode[p.key] = value
        }
        do{
            return try JSONSerialization.data(withJSONObject: dictToEncode, options: .prettyPrinted)
        }catch{
            print(error)
            return nil
        }
    }
    
    /// Import uniforms from json data
    /// - Parameters:
    ///   - json: json data
    ///   - type: Metal type that will be useed to address uniforms in Metal library code
    ///   - name: Name of variable by which uniforms will be accessible in Metal library code
    func `import`(json: Data, type: String? = nil, name: String? = nil){
        guard let object = try? JSONSerialization.jsonObject(with: json)
        else { return }
        guard let dict = object as? [String:Any]
        else {
            print("bad json")
            return
        }
        var selfDict = self.dict
        for d in dict{
            if var property = selfDict[d.key]{
                switch property.type{
                case .float:
                    if let value = d.value as? Float{
                        setFloat(value, for: d.key)
                        property.initValue = [value]
                    }
                case .float2:
                    if let value = d.value as? [Float]{
                        setFloat2(value, for: d.key)
                        property.initValue = value
                    }
                case .float3:
                    if let value = d.value as? [Float]{
                        setFloat3(value, for: d.key)
                        property.initValue = value
                    }
                case .float4:
                    if let value = d.value as? [Float]{
                        setFloat4(value, for: d.key)
                        property.initValue = value
                    }
                }
                selfDict[d.key] = property
            }
        }
        self.dict = selfDict
    }
}

