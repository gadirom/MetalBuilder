import MetalKit
import SwiftUI
//import OrderedCollections

public protocol UniformProtocol{
    associatedtype T
    associatedtype Tt: Comparable
    init(_ initValue: T, range: ClosedRange<Tt>, editable: Bool)
    
    var binding: Binding<T>!    { get }
    var range: ClosedRange<Tt>  { get }
    var initValue: T            { get }
    var editable: Bool          { get }
    
    var offset: Int            { get }
    
    var value: T               { get }
}

public struct Uniform<T, Tt: Comparable>: UniformProtocol{
    internal init(binding: Binding<T>? = nil, range: ClosedRange<Tt>, initValue: T, editable: Bool, offset: Int = 0) {
        self.binding = binding
        self.range = range
        self.initValue = initValue
        self.editable = editable
        self.offset = offset
    }
    
    public init(_ initValue: T, range: ClosedRange<Tt>, editable: Bool=true) {
        self.range = range
        self.initValue = initValue
        self.editable = editable
    }
    
    public var binding: Binding<T>!

public let range: ClosedRange<Tt>
public let initValue: T
public let editable: Bool

public var offset: Int = 0

public var value: T{
    binding.wrappedValue
}
}

extension MTLBufferContainer where T == UInt8{
func setUniformValue<S>(_ value: S, offset: Int){
    self.buffer!.contents()
        .advanced(by: offset)
        .bindMemory(to: S.self, capacity: 1)
        .pointee = value
}
func getUniformValue<S>(offset: Int)->S{
    self.buffer!.contents()
        .advanced(by: offset)
        .bindMemory(to: S.self, capacity: 1)
        .pointee
}
}
