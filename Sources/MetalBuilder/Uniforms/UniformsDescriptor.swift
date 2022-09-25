import SwiftUI

import OrderedCollections
import MetalKit
import SwiftUI

struct Property{
    let type: UniformsPropertyType
    var offset: Int = 0
    let range: ClosedRange<Float>?
    var initValue: [Float]
    var show: Bool
}

public struct UniformsDescriptor{
    public init() {}
    private(set) var dict: OrderedDictionary<String, Property> = [:]
}
public extension UniformsDescriptor{
    
    func float(_ name: String, range: ClosedRange<Float>? = nil, value: Float = 0, show: Bool=true)->UniformsDescriptor{
        var u = self
        u.dict[name] = Property(type: .float, range: range, initValue: [value], show: show)
        return u
    }
    func float2(_ name: String, range: ClosedRange<Float>? = nil, value: [Float] = [0, 0], show: Bool=true)->UniformsDescriptor{
        var u = self
        u.dict[name] = Property(type: .float2, range: range, initValue: value, show: show)
        return u
    }
    func float3(_ name: String, range: ClosedRange<Float>? = nil, value: [Float] = [0, 0, 0], show: Bool=true)->UniformsDescriptor{
        var u = self
        u.dict[name] = Property(type: .float3, range: range, initValue: value, show: show)
        return u
    }
    func float4(_ name: String, range: ClosedRange<Float>? = nil, value: [Float] = [0, 0, 0, 0], show: Bool=true)->UniformsDescriptor{
        var u = self
        u.dict[name] = Property(type: .float4, range: range, initValue: value, show: show)
        return u
    }
}
