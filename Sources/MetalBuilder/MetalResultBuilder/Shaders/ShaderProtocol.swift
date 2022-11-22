import SwiftUI

public protocol ShaderProtocol {
    var body: String? { get set}
    var source: String? { get set }

//Declaration of public modifiers
    func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int, argument: MetalBufferArgument) -> ShaderProtocol
    
    func bytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument) -> ShaderProtocol
    
    func bytes<T>(_ binding: MetalBinding<T>, space: String, type: String, name: String, index: Int)->ShaderProtocol
    
    func texture(_ container: MTLTextureContainer, argument: MetalTextureArgument) -> ShaderProtocol
    
    func uniforms(_ uniforms: UniformsContainer, name: String) -> ShaderProtocol
    func source(_ source: String)->ShaderProtocol
    func body(_ body: String)->ShaderProtocol
}

//contains wrapper for the functions with default parameters
extension ShaderProtocol{
    public func bytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil, name: String?=nil, index: Int?=nil)->ShaderProtocol{
        return bytes(binding, space: space, type: type, name: name, index: index)
    }
    public func uniforms(_ uniforms: UniformsContainer, name: String?=nil) -> ShaderProtocol{
        return self.uniforms(uniforms, name: name)
    }
}

//Internal implementation for ShaderProtocol's logic
//This is hidden from the client
protocol InternalShaderProtocol: ShaderProtocol{
    var bufsAndArgs: [(BufferProtocol, MetalBufferArgument)] { get set }
    var bytesAndArgs: [(BytesProtocol, MetalBytesArgument)] { get set }
    var texsAndArgs: [(Texture, MetalTextureArgument)] { get set }
    
    var uniformsAndNames: [(UniformsContainer, String?)] { get set }
}

//Implementation of public modifiers for ShaderProtocol
extension InternalShaderProtocol{
    public func buffer<T>(_ container: MTLBufferContainer<T>, offset: Int, argument: MetalBufferArgument) -> ShaderProtocol{
        var sh = self
        let buf = Buffer(container: container, offset: offset, index: 0)
        sh.bufsAndArgs.append((buf, argument))
        return sh
    }
    public func bytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument) -> ShaderProtocol{
        var sh = self
        let bytes = Bytes(binding: binding, index: 0)
        sh.bytesAndArgs.append((bytes, argument))
        return sh
    }
    public func bytes<T>(_ binding: MetalBinding<T>, space: String, type: String, name: String, index: Int)->ShaderProtocol{
        let argument = MetalBytesArgument(binding: binding, space: space, type: type, name: name)
        return bytes(binding.binding, argument: argument)
    }
    public func texture(_ container: MTLTextureContainer, argument: MetalTextureArgument) -> ShaderProtocol{
        var sh = self
        let tex = Texture(container: container, index: 0)
        sh.texsAndArgs.append((tex, argument))
        return sh
    }
    public func uniforms(_ uniforms: UniformsContainer, name: String) -> ShaderProtocol{
        var sh = self
        sh.uniformsAndNames.append((uniforms, name))
        return sh
    }
    public func source(_ source: String)->ShaderProtocol{
        var sh = self
        sh.source = source
        return sh
    }
    public func body(_ body: String)->ShaderProtocol{
        var sh = self
        sh.body = body
        return sh
    }
}

