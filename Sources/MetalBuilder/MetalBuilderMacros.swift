
//@attached(member, names: named(init))
//public macro UniformsStruct() = #externalMacro(module: "MetalBuilderMacros", type: "UniformsStructMacro")


// Combine both macros in a single attribute
//@attached(peer)
//@attached(member, names: named(collectProperties), named(init))
//public macro UniformsStruct(_ parentClass: String) = #externalMacro(module: "MetalBuilderMacros", type:  "PropertyCollectorMacro")


// MARK: - Register Macros

@attached(peer, names: arbitrary)
public macro Field(_ style: FieldStyle, _ title: String) = #externalMacro(module: "MetalBuilderMacros", type: "FieldMacro")

@attached(member, names: named(dict), named(subscript))
public macro Editable() = #externalMacro(module: "MetalBuilderMacros", type: "EditableMacro")
