import SwiftUI

import OrderedCollections
import MetalKit
import SwiftUI

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
public struct StructDescriptor<T: UniformFields>{
    public init() {
        self.fields = []
    }
    private init(fields: [UniformField]){
        self.fields = fields
    }
    let fields: [UniformField]
    
    func field(index: Int,
               name: String,
               _ initValue: Any,
               style: FieldStyle) -> Self{
        var fields = fields
        fields.append(.init(
            name: name,
            index: index,
            initValue: initValue,
            style: style))
        return .init()
    }
}
public extension StructDescriptor{
    func field(_ case: T,
               _ initValue: Any,
               style: FieldStyle) -> Self{
        self.field(index: `case`.index,
                   name: `case`.name,
                   initValue,
                   style: style)
    }
}

public struct UniformField{
    let name: String
    let index: Int
    let initValue: Any
    let style: FieldStyle
}
