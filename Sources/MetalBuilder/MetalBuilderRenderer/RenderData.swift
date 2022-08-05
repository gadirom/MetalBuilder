
import MetalKit
import SwiftUI

final class LibraryContainer{
    var library: MTLLibrary?
}

struct RenderData{
    var passes: [MetalPass] = []
    
    //some of these textures needs to be recreated on resize
    //that's why I keep track on them
    var textures: [MTLTextureContainer] = []
    
    var functionsAndArgumentsToAddToMetal: [FunctionAndArguments] = []
    
    //var libraryBindings: [LibraryContainer] = []
    
    var pixelFormat: MTLPixelFormat?
    //var device: MTLDevice!
    
    var context: MetalBuilderRenderingContext!
    
    init(){}
    
    init(from renderingContent: MetalRenderingContent,
         librarySource: String,
         options: MetalBuilderCompileOptions,
         context: MetalBuilderRenderingContext,
         device: MTLDevice,
         pixelFormat: MTLPixelFormat) throws{
        
        self.context = context
        //self.device = device
        self.pixelFormat = pixelFormat
        
        let content = renderingContent(context)
        //var libraryContainer = LibraryContainer()
        
        let data = try Self.compile(device:device,
                                    pixelFormat: pixelFormat,
                                    content: content,
                                    librarySource: librarySource,
                                    options: options,
                                    context: context)
        self.append(data)
        
        try data.setupPasses(device: device)
        try data.createTextures(context: context, device: device)
    }
    
    static func compile(device: MTLDevice,
                        pixelFormat: MTLPixelFormat,
                        content: MetalContent,
                        librarySource: String,
                        options: MetalBuilderCompileOptions,
                        context: MetalBuilderRenderingContext) throws -> Self{
        
        var librarySource = librarySource
        let libraryContainer = LibraryContainer()
        
        return try compile(device: device,
                           pixelFormat: pixelFormat,
                           content: content,
                           librarySource: &librarySource,
                           libraryContainer: libraryContainer,
                           options: options,
                           context: context,
                           level: 0)
    }
    
    static func compile(device: MTLDevice,
                        pixelFormat: MTLPixelFormat,
                        content: MetalContent,
                        librarySource: inout String,
                        libraryContainer: LibraryContainer,
                        options: MetalBuilderCompileOptions,
                        context: MetalBuilderRenderingContext,
                        level: Int) throws -> Self{
        
        var data = RenderData()
        //data.device = device
        //data.pixelFormat = pixelFormat
        
        //init passes
        for component in content{
            //Compute
            if let computeComponent = component as? Compute{
                data.passes.append(ComputePass(computeComponent, libraryContainer: libraryContainer))
                data.addTextures(newTexs: computeComponent.textures.map{ $0.container })
                try data.createBuffers(buffers: computeComponent.buffers, device: device)
                
                if librarySource != ""{
                
                    //arguments for functions
                    let kernel = MetalFunction.compute(computeComponent.kernel)
                    let funcAndArg = FunctionAndArguments(function: kernel,
                                                          arguments: computeComponent.kernelArguments)
                    data.functionsAndArgumentsToAddToMetal
                        .append(funcAndArg)
                }
            }
            //Render
            if let renderComponent = component as? Render{
                data.passes.append(RenderPass(renderComponent, libraryContainer: libraryContainer))
                data.addTextures(newTexs: renderComponent.vertexTextures.map{ $0.container })
                data.addTextures(newTexs: renderComponent.fragTextures.map{ $0.container })
                data.addTextures(newTexs: renderComponent.colorAttachments.values.map{ $0.texture })
                try data.createBuffers(buffers: renderComponent.vertexBufs, device: device)
                try data.createBuffers(buffers: renderComponent.fragBufs, device: device)
                
                if librarySource != ""{
                    
                    //arguments for functions
                    let vertex = MetalFunction.vertex(renderComponent.vertexFunc)
                    let vertexAndArg = FunctionAndArguments(function: vertex,
                                                            arguments: renderComponent.vertexArguments)
                    data.functionsAndArgumentsToAddToMetal
                        .append(vertexAndArg)
                    
                    let fragment = MetalFunction.vertex(renderComponent.vertexFunc)
                    let fragAndArg = FunctionAndArguments(function: fragment,
                                                            arguments: renderComponent.fragmentArguments)
                    data.functionsAndArgumentsToAddToMetal
                        .append(fragAndArg)
                }
                
            }
            //Manual Encode
            if let manualEncodeComponent = component as? ManualEncode{
                data.passes.append(ManualEncodePass(manualEncodeComponent))
            }
            //MPSUnary
            if let mpsUnaryComponent = component as? MPSUnary{
                data.addTextures(newTexs: [mpsUnaryComponent.inTexture, mpsUnaryComponent.outTexture])
                data.passes.append(MPSUnaryPass(mpsUnaryComponent))
            }
            //Blit Texture
            if let blitTextureComponent = component as? BlitTexture{
                data.addTextures(newTexs: [blitTextureComponent.inTexture, blitTextureComponent.outTexture])
                data.passes.append(BlitTexturePass(blitTextureComponent))
            }
            //Blit Buffer
            if let blitBufferComponent = component as? BlitBuffer{
                try data.createBuffers(buffers: [blitBufferComponent.inBuffer!,
                                                blitBufferComponent.outBuffer!],
                                       device: device)
                data.passes.append(BlitBufferPass(blitBufferComponent))
            }
            //EncodeGroup
            if let encodeGroupComponent = component as? EncodeGroup{
                let groupData = try compile(
                    device: device,
                    pixelFormat: pixelFormat,
                    content: encodeGroupComponent.metalContent,
                    librarySource: &librarySource,
                    libraryContainer: libraryContainer,
                    options: options,
                    context: context,
                    level: level+1
                )
                data.textures.append(contentsOf: groupData.textures)
                let groupPass = EncodeGroupPass(groupData.passes, repeating: encodeGroupComponent.repeating)
                data.passes.append(groupPass)
            }
            //Building Block
            if let buildingBlockComponent = component as? MetalBuildingBlock{
                if let options = buildingBlockComponent.compileOptions{
                    //compile to it's own library
                    let blockData = try compile(
                        device: device,
                        pixelFormat: pixelFormat,
                        content: buildingBlockComponent.metalContent,
                        librarySource: buildingBlockComponent.librarySource,
                        options: options,
                        context: context
                    )
                    data.append(blockData)
                }else{
                    //compile to shared library
                    librarySource = buildingBlockComponent.librarySource + librarySource
                    
                    let blockData = try compile(
                        device: device,
                        pixelFormat: pixelFormat,
                        content: buildingBlockComponent.metalContent,
                        librarySource: &librarySource,
                        libraryContainer: libraryContainer,
                        options: options,
                        context: context,
                        level: level+1
                    )
                    data.append(blockData)
                }
            }
        }
        
        //setup library only if current compile has to have its own separate library
        if level == 0{

            if librarySource == ""{
                libraryContainer.library = device.makeDefaultLibrary()
            }else{
                
                try parse(library: &librarySource,
                          funcArguments: data.functionsAndArgumentsToAddToMetal)
                
                switch options.libraryPrefix{
                case .`default`: librarySource = kMetalBuilderDefaultLibraryPrefix + librarySource
                case .custom(let prefix): librarySource = prefix + librarySource
                }
                libraryContainer.library = try device.makeLibrary(source: librarySource, options: options.mtlCompileOptions)
            }
        }
        return data
    }
    
    //adds only unique textures
    mutating func addTextures(newTexs: [MTLTextureContainer?]){
        let newTextures = newTexs.compactMap{ $0 }
            .filter{ newTexture in
                !textures.contains{ oldTexture in
                    newTexture === oldTexture
                }
            }
        textures.append(contentsOf: newTextures)
    }
    
    func createTextures(context: MetalBuilderRenderingContext, device: MTLDevice) throws{
        //create textures
        for tex in textures{
            do{
                try tex.create(device: device,
                               viewportSize: context.viewportSize,
                               pixelFormat: pixelFormat)
            }catch{
                print(error)
            }
        }
    }
    
    func updateTextures(device: MTLDevice) throws{
        for tex in textures{
            if case .fromViewport = tex.descriptor.size{
                do{
                    try tex.create(device: device,
                                   viewportSize: context.viewportSize,
                                   pixelFormat: pixelFormat)
                }catch{
                    print(error)
                }
            }
        }
    }
    
    func setupPasses(device: MTLDevice) throws{
        //setup passes
        for pass in passes{
            try pass.setup(device: device)
        }
    }
    
    //creates only new buffers
    func createBuffers(buffers: [BufferProtocol], device: MTLDevice) throws{
        for buf in buffers{
            if buf.mtlBuffer == nil {
                try buf.create(device: device)
            }
        }
    }
    
    static func addSwiftTypes(from buffers: [BufferProtocol], to swiftTypes: inout [SwiftTypeToMetal]){
        for buf in buffers {
            if let type = buf.swiftTypeToMetal{
                swiftTypes.append(type)
            }
        }
    }
    
    mutating func append(_ data: RenderData){
        passes.append(contentsOf: data.passes)
        textures.append(contentsOf: data.textures)
        
        functionsAndArgumentsToAddToMetal
            .append(contentsOf: data.functionsAndArgumentsToAddToMetal)
        
        //libraryBindings.append(contentsOf: data.libraryBindings)
    }
}
