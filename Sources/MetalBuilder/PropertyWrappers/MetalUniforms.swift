//
//  MetalUniforms.swift
//  
//
//  Created by Roman Gaditskiy on 04.11.2022.
//

import Foundation

@propertyWrapper
/// Use this property wrapper to create an instance of UniformsContainer to pass it to your MetalBuilder components
public final class MetalUniforms{
    public var wrappedValue: UniformsContainer
    
    public init(wrappedValue: UniformsContainer){
        self.wrappedValue = wrappedValue
    }
    /// Creates an instance of UniformsContainer with the provided descriptor.
    ///
    /// Don't call this initializer directly. Instead, declare a property
    /// with the ``MetalUniforms`` attribute, and provide a configured UniformsDescriptor struct:
    ///
    ///     @MetalUniforms(UniformsDescriptor(packed: false)
    ///                         .float4("someColor")
    ///                         .float4("someValue"),
    ///                         type("Uniforms"),
    ///                         name("u")
    ///     ) private var uniforms
    ///
    /// The above exaple will tell MetalBuilder to create the following struct in Metal library code:
    ///
    ///     struct Uniforms{
    ///         float4 someColor;
    ///         float4 someValue;
    ///     };
    ///
    /// It will then adds the following line to the declaration of whatever shaders you want the uniforms to be received by:
    ///
    ///     constant Uniforms& u [[buffer(index)]] // the 'index' is generated automatically
    ///
    /// Then you will be able to access the uniforms properties in the shader code:
    ///
    ///     float4 color = u.someColor;
    ///     float value = u.someValue.x;
    ///
    /// To use unforms you pass the uniforms container to the MetalBuilder component with the chaining modifier:
    ///
    ///      Render(vertex: "vertexShader", fragment: "fragmentShader")
    ///         .uniforms(uniforms)
    ///
    /// If you want to create an instance of UniformsContainer directrly use it's own initializer.
    /// - Parameters:
    ///   - descriptor: The descriptor that contains the properties of the uniforms.
    ///   - type: The type name for the Metal struct for uniforms.
    ///   - name: The name of the parameter by which the uniforms struct will be passed to your shaders.
    ///   - saveToDefaults: Indicates whether the uniforms should be saved in User Defaults system
    ///   persistently across launches of your app.
    public init(_ descriptor: UniformsDescriptor,
                type: String? = nil,
                name: String? = nil,
                saveToDefaults: Bool = true){
        self.wrappedValue = UniformsContainer(descriptor,
                                              type: type,
                                              name: name,
                                              saveToDefaults: saveToDefaults)
    }
}
