
import MetalKit

//String, String = shaderName, argument
enum ArgumentsContainerError: Error{
    case sameArgumentBuffer(String, String)// shaderName, argument
    case sameArgument(String, String, ResourceType)// shaderName, argument
    case sameNamedArguments(String, String)// shaderName, resource metal name
}
extension ArgumentsContainerError: LocalizedError{
    public var errorDescription: String?{
        switch self {
        case .sameArgumentBuffer(let shaderName, let argument):
            return "Same argument buffer ('\(argument)') was provided twice for the shader '\(shaderName)'"
        case .sameArgument(let shaderName, let argument, let dataType):
            return "Same \(String(describing: dataType)) ('\(argument)') was provided twice for the shader '\(shaderName)'"
        case .sameNamedArguments(let shaderName, let argumentName):
            return "Two resources of the same name ('\(argumentName)') were provided for the shader '\(shaderName)'"
        }
    }
}

extension ArgumentsContainer{
    func checkIfBufferIsNew(buf: BufferProtocol,
                            argumentName: String){
        do{
            if self.buffersAndBytesContainer.buffers.contains(where: { $0 === buf }){
                throw ArgumentsContainerError
                    .sameArgument(argumentName, shaderName, .buffer)
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
                    .sameArgument(shaderName, argumentName, .texture)
            }
        }catch{
            fatalError(error.localizedDescription)
        }
    }
    func checkForSameNames(name: String){
        do{
            if self.separateShaderArguments.contains(where: { $0.name == name }){
                throw ArgumentsContainerError
                    .sameNamedArguments(shaderName, name)
            }
        }catch{
            fatalError(error.localizedDescription)
        }
    }
    func checkIfArgumentBufferIsNew(_ argumentBuffer: ArgumentBuffer){
        do{
            for argBuf in addedArgumentBuffers{
                if argBuf.0 === argumentBuffer{
                    throw ArgumentsContainerError.sameArgumentBuffer(shaderName, argumentBuffer.name)
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

