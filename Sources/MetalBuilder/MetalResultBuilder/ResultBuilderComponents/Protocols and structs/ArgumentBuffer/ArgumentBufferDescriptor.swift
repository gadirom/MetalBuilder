import MetalKit

struct ArgumentBufferDescriptorEntry{
    let resource: MTLResourceContainer
    let offset: MetalBinding<Int>
}

public struct ArgumentBufferDescriptor{
    
    let type: String?
    var arguments: [(ArgumentBufferDescriptorEntry, MetalFunctionArgument)] = []
    public init(_ type: String?=nil){
        self.type = type
    }
}
public extension ArgumentBufferDescriptor{
    func buffer<T>(_ container: MTLBufferContainer<T>, name: String?=nil,
                   offset: MetalBinding<Int> = .constant(0),
                    space: String="constant", type: String?=nil)->Self{
        var d = self
        try! d.arguments.append((ArgumentBufferDescriptorEntry(resource: container,
                                                         offset: offset),
                            .buffer(MetalBufferArgument(container,
                                                        space: space,
                                                        type: type,
                                                        name: name,
                                                        index: d.arguments.count))))
        return d
    }
//    func addBytes<T>(_ bytes: Bytes<T>, bytesArgument: MetalBytesArgument){
//        var bytes = bytes
//        bytes.index = argumentsCounter
//        arguments.append(.bytes(bytesArgument))
//        //bytes.addToArgumentBuffer(self, id: argumentsCounter)
//        argumentsCounter += 1
//    }
    func texture(_ container: MTLTextureContainer,
                 argument: MetalTextureArgument)->Self{
        var d = self
        var argument = argument
        argument.textureType = container.descriptor.type
        argument.index = d.arguments.count
        d.arguments.append((ArgumentBufferDescriptorEntry(resource: container,
                                                         offset: .constant(0)),
        
                            .texture(argument)))
        return d
    }
}
