
import MetalKit

//String, String = shaderName, argument
enum ArgumentsContainerError: Error{
    case sameArgumentBuffer(String)//  argument
    case sameArgument(String, ResourceType)// argument
    case sameNamedArguments(String)// resource metal name
}
extension ArgumentsContainerError: LocalizedError{
    public var errorDescription: String?{
        switch self {
        case .sameArgumentBuffer(let argument):
            return "Same argument buffer ('\(argument)') was provided twice for a shader!"
        case .sameArgument(let argument, let dataType):
            return "Same \(String(describing: dataType)) ('\(argument)') was provided twice for a shader!"
        case .sameNamedArguments(let argumentName):
            return "Two resources of the same name ('\(argumentName)') were provided for a shader!"
        }
    }
}

extension ArgumentsContainer{
    func checkIfBufferIsNew(buf: BufferProtocol,
                            argumentName: String){
        do{
            if self.buffersAndBytesContainer.buffers.contains(where: { $0 === buf }){
                throw ArgumentsContainerError
                    .sameArgument(argumentName, .buffer)
            }
        }catch{
            fatalError(error.localizedDescription)
        }
    }
    func checkIfTextureIsNew(container: MTLTextureContainer,
                             argumentName: String){
        do{
            if self.texturesContainer.textures.contains(where: { $0.container === container }){
                throw ArgumentsContainerError
                    .sameArgument(argumentName, .texture)
            }
        }catch{
            fatalError(error.localizedDescription)
        }
    }
    func checkForSameNames(name: String){
        do{
            if self.separateShaderArguments.contains(where: { $0.name == name }){
                throw ArgumentsContainerError
                    .sameNamedArguments(name)
            }
        }catch{
            fatalError(error.localizedDescription)
        }
    }
    func checkIfArgumentBufferIsNew(_ argumentBuffer: ArgumentBuffer){
        do{
            for argBuf in addedArgumentBuffers{
                if argBuf.0 === argumentBuffer{
                    throw ArgumentsContainerError
                        .sameArgumentBuffer(argumentBuffer.name)
                }
            }
        }catch{
            fatalError(error.localizedDescription) 
        }
    }
}

extension MTLDataType{
    var label: String{
        switch self.rawValue {
        case 2:
            "array"
        case 58:
            "texture"
        case 59:
            "sampler"
        case 60:
            "pointer"
        default:
            "unknown type"
        }
    }
}

