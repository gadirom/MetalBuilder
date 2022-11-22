import SwiftUI

public protocol ShaderProtocol {
    var body: String? { get set}
    var source: String? { get set }
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
//They are to be called by wrappers of the respective shaders
extension InternalShaderProtocol{
    func _buffer<T>(_ container: MTLBufferContainer<T>, offset: Int, argument: MetalBufferArgument) -> ShaderProtocol{
        var sh = self
        let buf = Buffer(container: container, offset: offset, index: 0)
        sh.bufsAndArgs.append((buf, argument))
        return sh
    }
    func _bytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument) -> ShaderProtocol{
        var sh = self
        let bytes = Bytes(binding: binding, index: 0)
        sh.bytesAndArgs.append((bytes, argument))
        return sh
    }
    func _bytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil, name: String?=nil, index: Int?=nil)->ShaderProtocol{
        let argument = MetalBytesArgument(binding: binding, space: space, type: type, name: name)
        return _bytes(binding.binding, argument: argument)
    }
    func _texture(_ container: MTLTextureContainer, argument: MetalTextureArgument) -> ShaderProtocol{
        var sh = self
        let tex = Texture(container: container, index: 0)
        sh.texsAndArgs.append((tex, argument))
        return sh
    }
    func _uniforms(_ uniforms: UniformsContainer, name: String?=nil) -> ShaderProtocol{
        var sh = self
        sh.uniformsAndNames.append((uniforms, name))
        return sh
    }
    func _source(_ source: String)->ShaderProtocol{
        var sh = self
        sh.source = source
        return sh
    }
    func _body(_ body: String)->ShaderProtocol{
        var sh = self
        sh.body = body
        return sh
    }
}

