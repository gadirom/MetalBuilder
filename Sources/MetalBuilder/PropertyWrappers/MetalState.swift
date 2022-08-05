
import SwiftUI

@propertyWrapper
public final class MetalState<T>{
    public var wrappedValue: T
    public var projectedValue: MetalBinding<T>{
        MetalBinding<T>(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 })
    }
    public init(wrappedValue: T){
        self.wrappedValue = wrappedValue
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
    
    public init(get: @escaping ()->T, set: @escaping (T)->()){
        binding = Binding(get: get, set: set)
    }
}
