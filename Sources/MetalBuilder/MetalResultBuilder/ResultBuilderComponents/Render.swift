import MetalKit
import SwiftUI

enum MetalDSPRenderSetupError: Error{
    //case noGridFit(String)
}
/// color attachment with bindings
struct ColorAttachment{
    var texture: MTLTextureContainer?
    var loadAction: Binding<MTLLoadAction>?
    var storeAction: Binding<MTLStoreAction>?
    var clearColor: Binding<MTLClearColor>?
    
    var descriptor: MTLRenderPassColorAttachmentDescriptor{
        let d = MTLRenderPassColorAttachmentDescriptor()
        d.texture = texture?.texture
        if let loadAction = loadAction?.wrappedValue{
            d.loadAction = loadAction
        }
        if let storeAction = storeAction?.wrappedValue{
            d.storeAction = storeAction
        }
        if let clearColor = clearColor?.wrappedValue{
            d.clearColor = clearColor
        }
        return d
    }
}
/// default color attachments
var defaultColorAttachments =
    [0:ColorAttachment(texture: nil,
                       loadAction: Binding<MTLLoadAction>(
                        get: { .clear },
                        set: { _ in }),
                       storeAction: Binding<MTLStoreAction>(
                        get: { .store },
                        set: { _ in }),
                       clearColor: Binding<MTLClearColor>(
                        get: { MTLClearColorMake(0.0, 0.0, 0.0, 1.0)},
                        set: { _ in } )
                       )]
/// Render Component
public struct Render: MetalBuilderComponent{
    
    let vertexFunc: String
    let fragmentFunc: String
    
    var type: MTLPrimitiveType!
    var vertexStart: Int
    var vertexCount: Int
    
    var viewport: Binding<MTLViewport>?
    
    var vertexBufs: [BufferProtocol] = []
    var vertexBytes: [BytesProtocol] = []
    var vertexTextures: [Texture] = []
    
    var fragBufs: [BufferProtocol] = []
    var fragBytes: [BytesProtocol] = []
    var fragTextures: [Texture] = []
    
    var colorAttachments: [Int: ColorAttachment] = defaultColorAttachments
    
    var vertexArguments: [MetalFunctionArgument] = []
    var fragmentArguments: [MetalFunctionArgument] = []
    
    var vertexBufferIndexCounter = 0
    var fragmentBufferIndexCounter = 0
    var vertexTextureIndexCounter = 0
    var fragmentTextureIndexCounter = 0
    
    public init(vertex: String, fragment: String, type: MTLPrimitiveType = .triangle, start: Int = 0, count: Int = 3){
        self.vertexFunc = vertex
        self.fragmentFunc = fragment
        
        self.type = type
        self.vertexStart = start
        self.vertexCount = count
    }
    
    mutating func setup() throws{
    }
}
// chaining functions for result builder
public extension Render{
    func primitives(_ type: MTLPrimitiveType = .triangle, start: Int = 0, count: Int = 3)->Render{
        var r = self
        r.type = type
        r.vertexStart = start
        r.vertexCount = count
        return r
    }
    func vertexBuf<T>(_ container: MTLBufferContainer<T>, offset: Int = 0, index: Int)->Render{
        var r = self
        let buf = Buffer(container: container, offset: offset, index: index)
        r.vertexBufs.append(buf)
        return r
    }
    func vertexBuf<T>(_ container: MTLBufferContainer<T>, offset: Int = 0, argument: MetalBufferArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkVertexBufferIndex(r: &r, index: argument.index)
        r.vertexArguments.append(MetalFunctionArgument.buffer(argument))
        let buf = Buffer(container: container, offset: offset, index: argument.index!)
        r.vertexBufs.append(buf)
        return r
    }
    func vertexBuf<T>(_ container: MTLBufferContainer<T>, offset: Int = 0,
                   space: String = "constant", type: String?=nil, name: String?=nil) -> Render{
        
        let argument = try! MetalBufferArgument(container, space: space, type: type, name: name)

        return self.vertexBuf(container, offset: offset, argument: argument)
    }
    func fragBuf<T>(_ container: MTLBufferContainer<T>, offset: Int, index: Int)->Render{
        var r = self
        let buf = Buffer(container: container, offset: offset, index: index)
        r.fragBufs.append(buf)
        return r
    }
    func fragBuf<T>(_ container: MTLBufferContainer<T>, offset: Int, argument: MetalBufferArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkFragmentBufferIndex(r: &r, index: argument.index)
        r.fragmentArguments.append(.buffer(argument))
        let buf = Buffer(container: container, offset: offset, index: argument.index!)
        r.fragBufs.append(buf)
        return r
    }
    func fragBuf<T>(_ container: MTLBufferContainer<T>, offset: Int = 0,
                   space: String, type: String?=nil, name: String?=nil) -> Render{
        
        let argument = try! MetalBufferArgument(container, space: space, type: type, name: name)

        return self.fragBuf(container, offset: offset, argument: argument)
        
    }
    func vertexBytes<T>(_ binding: Binding<T>, index: Int)->Render{
        var r = self
        let bytes = Bytes(binding: binding, index: index)
        r.vertexBytes.append(bytes)
        return r
    }
    func vertexBytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkVertexBufferIndex(r: &r, index: argument.index)
        r.vertexArguments.append(.bytes(argument))
        let bytes = Bytes(binding: binding, index: argument.index!)
        r.vertexBytes.append(bytes)
        return r
    }
    func vertexBytes<T>(_ binding: MetalBinding<T>, argument: MetalBytesArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkVertexBufferIndex(r: &r, index: argument.index)
        r.vertexArguments.append(.bytes(argument))
        let bytes = Bytes(binding: binding.binding, index: argument.index!)
        r.vertexBytes.append(bytes)
        return r
    }
    func vertexBytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil, name: String?=nil, index: Int?=nil)->Render{
        let argument = MetalBytesArgument(binding: binding, space: space, type: type, name: name)
        return vertexBytes(binding, argument: argument)
    }
    func fragBytes<T>(_ binding: Binding<T>, index: Int)->Render{
        var r = self
        let bytes = Bytes(binding: binding, index: index)
        r.fragBytes.append(bytes)
        return r
    }
    func fragBytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkFragmentBufferIndex(r: &r, index: argument.index)
        r.fragmentArguments.append(.bytes(argument))
        let bytes = Bytes(binding: binding, index: argument.index!)
        r.fragBytes.append(bytes)
        return r
    }
    func vertexTexture(_ container: MTLTextureContainer, index: Int)->Render{
        var r = self
        let tex = Texture(container: container, index: index)
        r.vertexTextures.append(tex)
        return r
    }
    func vertexTexture(_ container: MTLTextureContainer, argument: MetalTextureArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkVertexTextureIndex(r: &r, index: argument.index)
        r.vertexArguments.append(.texture(argument))
        let tex = Texture(container: container, index: argument.index!)
        r.vertexTextures.append(tex)
        return r
    }
    func fragTexture(_ container: MTLTextureContainer, index: Int)->Render{
        var r = self
        let tex = Texture(container: container, index: index)
        r.fragTextures.append(tex)
        return r
    }
    func fragTexture(_ container: MTLTextureContainer, argument: MetalTextureArgument)->Render{
        var r = self
        var argument = argument
        argument.index = checkVertexTextureIndex(r: &r, index: argument.index)
        r.fragmentArguments.append(.texture(argument))
        let tex = Texture(container: container, index: argument.index!)
        r.fragTextures.append(tex)
        return r
    }
    func viewport(_ viewport: Binding<MTLViewport>)->Render{
        var r = self
        r.viewport = viewport
        return r
    }
    func toTexture(_ container: MTLTextureContainer, index: Int = 0)->Render{
        var r = self
        var a: ColorAttachment
        if let aExistent = colorAttachments[index]{
            a = aExistent
        }else{
            a = ColorAttachment()
        }
        a.texture = container
        r.colorAttachments[index] = a
        return r
    }
}

extension Render{
    func checkVertexBufferIndex(r: inout Render, index: Int?) -> Int{
        if index == nil {
            let index = vertexBufferIndexCounter
            r.vertexBufferIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
    func checkVertexTextureIndex(r: inout Render, index: Int?) -> Int{
        if index == nil {
            let index = vertexTextureIndexCounter
            r.vertexTextureIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
    func checkFragmentBufferIndex(r: inout Render, index: Int?) -> Int{
        if index == nil {
            let index = fragmentBufferIndexCounter
            r.fragmentBufferIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
    func checkFragmentTextureIndex(r: inout Render, index: Int?) -> Int{
        if index == nil {
            let index = fragmentTextureIndexCounter
            r.fragmentTextureIndexCounter += 1
            return index
        }else{
            return index!
        }
    }
}
