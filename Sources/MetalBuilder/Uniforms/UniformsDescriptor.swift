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
    var group: String?
}

/// A struct that you use to configure new uniforms container
///
/// To create new uniforms container you either use MetalUniforms attribute
/// or directly initialize the UniformsContainer object.
/// In both cases you provide UniformsDescriptor struct configured via chaining modifiers:
///
///     UniformsDescriptor(packed: false)
///                             .float4("someColor")
///                             .float4("someValue")
///
public struct UniformsDescriptor{
    var currentGroup: String? = nil
    var packed: Bool
    /// Creates a uniforms descriptor struct.
    /// - Parameter packed: indicates whether you want to use Metal packed formats.
    ///       By default it's`true`.
    ///       Don't turn if off unless you absolutely sure that your properties would be aligned correctly!
    public init(packed: Bool=true) {
        self.packed = packed
    }
    private(set) var dict: OrderedDictionary<String, Property> = [:]
}
public extension UniformsDescriptor{
    
    func setCurrentGroup(_ group: String?)->UniformsDescriptor{
        var u = self
        u.currentGroup = group
        return u
    }
    
    func float(_ name: String, range: ClosedRange<Float>? = nil, value: Float = 0, show: Bool=true, group: String?=nil)->UniformsDescriptor{
        var u = self
        let g = if let group{ group } else { currentGroup }
        u.dict[name] = Property(type: .float, range: range, initValue: [value], show: show,
                                group: g)
        return u
    }
    func float2(_ name: String, range: ClosedRange<Float>? = nil, value: [Float] = [0, 0], show: Bool=true, group: String?=nil)->UniformsDescriptor{
        var u = self
        let g = if let group{ group } else { currentGroup }
        u.dict[name] = Property(type: .float2, range: range, initValue: value, show: show,
                                group: g)
        return u
    }
    func float3(_ name: String, range: ClosedRange<Float>? = nil, value: [Float] = [0, 0, 0], show: Bool=true, group: String?=nil)->UniformsDescriptor{
        var u = self
        let g = if let group{ group } else { currentGroup }
        u.dict[name] = Property(type: .float3, range: range, initValue: value, show: show,
                                group: g)
        return u
    }
    func float4(_ name: String, range: ClosedRange<Float>? = nil, value: [Float] = [0, 0, 0, 0], show: Bool=true, group: String?=nil)->UniformsDescriptor{
        var u = self
        let g = if let group{ group } else { currentGroup }
        u.dict[name] = Property(type: .float4, range: range, initValue: value, show: show,
                                group: g)
        return u
    }
    
    func merge(_ desc: UniformsDescriptor)->UniformsDescriptor{
        var u = self
        let _ = desc.dict.map{ key, value in
            var value = value
            if let currentGroup{
                value.group = currentGroup
            }
            u.dict[key] = value
        }
        return u
    }
    
}
