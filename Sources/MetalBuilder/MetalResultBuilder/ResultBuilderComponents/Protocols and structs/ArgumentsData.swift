import MetalKit

struct ArgumentsData{
    //Buffers a stored here and created after setupFunction of all the building blocks are done,
    //since there some properties of containers might be changed in a setupFunction.
    var buffers: [BufferProtocol] = []
    //All the individual textures that are used for encoding.
    //When MTKView first calls mtkView() to set size initially, the textures are created
    //(since you may need to know pixelFormat of the drawable for that).
    //Some of these textures needs to be recreated on resize
    //that's why I keep track on them
    var textures: [MTLTextureContainer] = []
    var uniforms: [UniformsContainer] = []
    var funcAndArgs: [FunctionAndArguments] = []
    
    var argBufDecls: String = ""
}
extension ArgumentsData{
    mutating func appendContents(of data: ArgumentsData){
        
        appendContentsExceptFuncArgs(of: data)
        
        funcAndArgs.append(contentsOf: data.funcAndArgs)
    }
    mutating func appendContentsExceptFuncArgs(of data: ArgumentsData){
        
        addTextures(newTexs: data.textures)
        
        addBuffers(newBuffs: data.buffers)
        
        addUniforms(newUni: data.uniforms)
        
        argBufDecls += data.argBufDecls
    }
    //adds only unique textures
    mutating func addTextures(newTexs: [MTLTextureContainer?]){
        let newTextures = newTexs.compactMap{ $0 }
            .filter{ newTexture in
                !textures.contains{ oldTexture in
                    newTexture === oldTexture
                }
            }.noDublicates()
        textures.append(contentsOf: newTextures)
    }
    
    //adds only unique buffers
    mutating func addBuffers(newBuffs: [BufferProtocol?]){
        let newBuffers = newBuffs.compactMap{ $0 }
            .filter{ newBuffer in
                !buffers.contains{ oldBuffer in
                    newBuffer === oldBuffer
                }
            }.noDublicates()
        buffers.append(contentsOf: newBuffers)
    }
    
    mutating func addUniforms(newUni: [UniformsContainer]){
        let newUniforms = newUni.compactMap{ $0 }
            .filter{ newUniforms in
                !textures.contains{ oldUniforms in
                    newUniforms === oldUniforms
                }
            }.noDublicates()
        uniforms.append(contentsOf: newUniforms)
    }
    func createUniforms(device: MTLDevice){
        _ = uniforms.map{ u in
            u.setup(device: device)
        }
    }
}
