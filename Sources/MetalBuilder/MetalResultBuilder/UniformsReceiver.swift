

protocol UniformsReceiver{
    var uniformsContainers: [UniformsContainer] { get set }
    var uniformsNames: [String?] { get set }
}
extension UniformsReceiver{
    public func uniforms(_ uniforms: UniformsContainer, name: String?=nil) -> Self{
        var c = self
        c.uniformsNames.append(name)
        c.uniformsContainers.append(uniforms)
        return c
    }
}
