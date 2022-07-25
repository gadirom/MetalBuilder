
import SwiftUI

@propertyWrapper
public final class MetalState<T>{
    public var wrappedValue: T
    public var projectedValue: Binding<T>{
        Binding<T>(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 })
    }
    public init(wrappedValue: T){
        self.wrappedValue = wrappedValue
    }
}
