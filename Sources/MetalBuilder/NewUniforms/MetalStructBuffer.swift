import MetalKit
import OrderedCollections

public class MetalStructBuffer {
    private var dataBuffer: Data
    private var fieldInfo: OrderedDictionary<String, FieldInfo>
    private let maxAlignment: Int
    
    struct FieldInfo {
        //let name: String
        let initValue: Any
        let type: Any.Type
        let size: Int
        let offset: Int
        let alignment: Int
        
        let style: FieldStyle
    }
    
    enum FieldError: Error {
        case invalidFieldName
        case invalidFieldIndex
        case typeMismatch(expected: Any.Type, actual: Any.Type)
        case dataOutOfBounds
    }
    
    public convenience init<T>(_ desc: StructDescriptor<T>) {
        self.init(fields: desc.fields)
    }
    
    public init(fields: [UniformField]) {
        var buffer = Data()
        var fieldInfo = OrderedDictionary<String, FieldInfo>()
        var offset = 0
        var maxAlignment = 1
        
        for field in fields {
            let typeInfo: (size: Int, alignment: Int, data: Data)
            
            switch field.initValue {
            case let val as UInt8:
                typeInfo = (
                    MemoryLayout<UInt8>.size,
                    MemoryLayout<UInt8>.alignment,
                    withUnsafeBytes(of: val) { Data($0) }
                )
            case let val as Int:
                typeInfo = (
                    MemoryLayout<Int>.size,
                    MemoryLayout<Int>.alignment,
                    withUnsafeBytes(of: val) { Data($0) }
                )
            case let val as UInt32:
                typeInfo = (
                    MemoryLayout<UInt32>.size,
                    MemoryLayout<UInt32>.alignment,
                    withUnsafeBytes(of: val) { Data($0) }
                )
            case let val as Float:
                typeInfo = (
                    MemoryLayout<Float>.size,
                    MemoryLayout<Float>.alignment,
                    withUnsafeBytes(of: val) { Data($0) }
                )
            case let val as SIMD2<Float>:
                typeInfo = (
                    MemoryLayout<SIMD2<Float>>.size,
                    MemoryLayout<SIMD2<Float>>.alignment,
                    withUnsafeBytes(of: val) { Data($0) }
                )
            case let val as SIMD3<Float>:
                typeInfo = (
                    MemoryLayout<SIMD3<Float>>.size,
                    MemoryLayout<SIMD3<Float>>.alignment,
                    withUnsafeBytes(of: val) { Data($0) }
                )
            case let val as SIMD4<Float>:
                typeInfo = (
                    MemoryLayout<SIMD4<Float>>.size,
                    MemoryLayout<SIMD4<Float>>.alignment,
                    withUnsafeBytes(of: val) { Data($0) }
                )
            default:
                fatalError("Unsupported type of \(field.name): \(type(of: field.initValue))")
            }
            
            maxAlignment = max(maxAlignment, typeInfo.alignment)
            let padding = (typeInfo.alignment - (offset % typeInfo.alignment)) % typeInfo.alignment
            buffer.append(Data(repeating: 0, count: padding))
            offset += padding
            
            let f = FieldInfo(
                initValue: field.initValue,
                type: type(of: field.initValue),
                size: typeInfo.size,
                offset: offset,
                alignment: typeInfo.alignment,
                style: field.style
            )
            let (v, i) = fieldInfo
                .updateValue(f,
                             forKey: field.name,
                             insertingAt: field.index)
            
            if v != nil{
                fatalError("Dublicate key of \(field.name)")
            }
            if i != field.index{
                fatalError("Dublicate index \(field.index) of \(field.name)")
            }
            
            buffer.append(typeInfo.data)
            offset += typeInfo.size
        }
        
        // Final padding
        let remainder = offset % maxAlignment
        if remainder != 0 {
            buffer.append(Data(repeating: 0, count: maxAlignment - remainder))
        }
        
        self.dataBuffer = buffer
        self.fieldInfo = fieldInfo
        self.maxAlignment = maxAlignment
    }
}

public extension MetalStructBuffer{
    
    // MARK: - Field Updates
    
    func updateField<T>(named name: String, with value: T) {
        let index = fieldInfo.index(forKey: name)!
        updateField(at: index, with: value)
    }
    
    func updateField<T>(at index: Int, with value: T) {
        let info = fieldInfo.values[index]
        let bytes: Data = withUnsafeBytes(of: value) { Data($0) }
        dataBuffer.replaceSubrange(
            info.offset..<info.offset + info.size,
            with: bytes
        )
    }
    
    func updateFieldSafe<T>(named name: String, with value: T) throws {
        guard let index = fieldInfo.index(forKey: name)
        else {
            throw FieldError.invalidFieldName
        }
        try updateFieldSafe(at: index, with: value)
    }
    
    func updateFieldSafe<T>(at index: Int, with value: T) throws {
        guard index < fieldInfo.count else {
            throw FieldError.invalidFieldIndex
        }
        
        let info = fieldInfo.values[index]
        guard type(of: value) == info.type else {
            throw FieldError.typeMismatch(expected: info.type, actual: type(of: value))
        }
        
        let bytes: Data = withUnsafeBytes(of: value) { Data($0) }
        
        guard bytes.count == info.size else {
            throw FieldError.dataOutOfBounds
        }
        
        dataBuffer.replaceSubrange(
            info.offset..<info.offset + info.size,
            with: bytes
        )
    }
    
    // MARK: - Field Access
    
    func getField<T>(named name: String) -> T {
        let index = fieldInfo.index(forKey: name)!
        return getField(at: index)
    }
    
    func getField<T>(at index: Int) -> T {
        dataBuffer.withUnsafeBytes { ptr in
            ptr.load(fromByteOffset: fieldInfo.values[index].offset, as: T.self)
        }
    }
    
    func getFieldSafe<T>(named name: String) throws -> T {
        guard let index = fieldInfo.index(forKey: name)
        else {
            throw FieldError.invalidFieldName
        }
        return try getFieldSafe(at: index)
    }
    
    func getFieldSafe<T>(at index: Int) throws -> T {
        guard index < fieldInfo.count else {
            throw FieldError.invalidFieldIndex
        }
        
        let info = fieldInfo.values[index]
        guard info.type == T.self else {
            throw FieldError.typeMismatch(expected: info.type, actual: T.self)
        }
        
        return try dataBuffer.withUnsafeBytes { ptr in
            guard ptr.baseAddress != nil else {
                throw FieldError.dataOutOfBounds
            }
            
            guard info.offset + info.size <= dataBuffer.count else {
                throw FieldError.dataOutOfBounds
            }
            
            return ptr.load(fromByteOffset: info.offset, as: T.self)
        }
    }
    
    // MARK: - Buffer Management
    
    var currentBuffer: Data {
        dataBuffer
    }
    
    func bindingFor<T>(name: String) -> MetalBinding<T>{
        let index = fieldInfo.index(forKey: name)!
        return .init(get: {
            self.getField(at: index)
        }, set: {
            self.updateField(at: index, with: $0)
        }, metalName: name)
    }
    
    func printLayout() {
        print("Buffer Layout (\(dataBuffer.count) bytes):")
        for (index, info) in fieldInfo.enumerated() {
            print("[\(index)] \(info.key) (\(String(describing: info.value)))")
            print("   Offset: \(info.value.offset), Size: \(info.value.size), Alignment: \(info.value.alignment)")
        }
        print("Total size: \(dataBuffer.count) bytes")
    }
}
