
import SwiftUI

@propertyWrapper
public final class MetalState<T>{
    public var wrappedValue: T
    public var projectedValue: MetalBinding<T>{
        MetalBinding<T>(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 },
            metalType: metalType,
            metalName: metalName)
    }
    var metalType: String?
    var metalName: String?
   
    public init(wrappedValue: T, metalType: String?=nil, metalName: String?=nil){
        self.wrappedValue = wrappedValue
        self.metalType = metalType
        self.metalName = metalName
    }
}

@propertyWrapper
public struct MetalBinding<T>{
    public var wrappedValue: T{
        get { binding.wrappedValue }
        nonmutating set { binding.wrappedValue = newValue }
    }
    public var projectedValue: Self { self }
    
    public let binding: Binding<T>
    
    var metalType: String?
    var metalName: String?
    
    public init(get: @escaping ()->T, set: @escaping (T)->(),
                metalType: String?=nil, metalName: String?=nil){
        self.binding = Binding(get: get, set: set)
        self.metalType = metalType
        self.metalName = metalName
    }
    public init(binding: Binding<T>,
                metalType: String?=nil, metalName: String?=nil){
        self.binding = binding
        self.metalType = metalType
        self.metalName = metalName
    }
    public static func constant(_ value: T, metalType: String? = nil, metalName: String? = nil) -> MetalBinding<T>{
        return MetalBinding<T>(get: { value },
                               set: {_ in },
                               metalType: metalType,
                               metalName: metalName)
    }
}

public struct BytesDescriptor{
    var metalType: String?
    var metalName: String?

    public init(metalType: String? = nil,
                metalName: String? = nil){
        self.metalName = metalName
        self.metalType = metalType
    }
}
public extension BytesDescriptor{
    func metalName(_ name: String) -> BytesDescriptor {
        var d = self
        d.metalName = name
        return d
    }
    func metalType(_ type: String) -> BytesDescriptor {
        var d = self
        d.metalType = type
        return d
    }
}

