
import MetalKit
import SwiftUI

final class LibraryContainer{
    var library: MTLLibrary?
}

struct RenderData{
    var passes: [MetalPass] = []
    
    //All the individual textures that are used for encoding.
    //When MTKView first calls mtkView() to set size initially, the textures are created
    //(since you may need to know pixelFormat of the drawable for that).
    //Some of these textures needs to be recreated on resize
    //that's why I keep track on them
    var textures: [MTLTextureContainer] = []
    var texturesCreated = false
    
    var functionsAndArgumentsToAddToMetal: [FunctionAndArguments] = []
    
//    var helpers = ""

    var renderInfo: GlobalRenderInfo!
    
    var context: MetalBuilderRenderingContext!
    
    //hold hashes for librarySources of BuildingBlocks to eliminate dublicates
    static var librarySourceHashes: [Int] = []
    //hold hashes for helpers of BuildingBlocks to eliminate dublicates when sibrarySource is imbedded into the components that constitute the given BuildingBlock
    static var helpersHashes: [Int] = []
    
    init(){}
    
    init(from renderingContent: MetalBuilderContent,
         librarySource: String,
         helpers: String,
         options: MetalBuilderCompileOptions,
         context: MetalBuilderRenderingContext,
         renderInfo: GlobalRenderInfo) throws{
        
        self.context = context
        //self.device = device
        self.renderInfo = renderInfo
        
        let content = renderingContent(context)
        //var libraryContainer = LibraryContainer()
        
        let data = try Self.compile(device: renderInfo.device,
                                    pixelFormat: renderInfo.pixelFormat,
                                    content: content,
                                    librarySource: librarySource,
                                    helpers: helpers,
                                    options: options,
                                    context: context)
        self.append(data)
        
        Self.librarySourceHashes = []
        Self.helpersHashes = []
        
        try data.setupPasses(renderInfo: renderInfo)
        //try data.createTextures(context: context, device: device)
    }
    
    static func compile(device: MTLDevice,
                        pixelFormat: MTLPixelFormat,
                        content: MetalContent,
                        librarySource: String,
                        helpers: String,
                        options: MetalBuilderCompileOptions,
                        context: MetalBuilderRenderingContext) throws -> Self{
        
        var librarySource = librarySource
        var helpers = helpers
        let libraryContainer = LibraryContainer()
        
        return try compile(device: device,
                           pixelFormat: pixelFormat,
                           content: content,
                           librarySource: &librarySource,
                           helpers: &helpers,
                           libraryContainer: libraryContainer,
                           options: options,
                           context: context,
                           level: 0)
    }
    
    static func compile(device: MTLDevice,
                        pixelFormat: MTLPixelFormat,
                        content: MetalContent,
                        librarySource: inout String,
                        helpers: inout String,
                        libraryContainer: LibraryContainer,
                        options: MetalBuilderCompileOptions,
                        context: MetalBuilderRenderingContext,
                        level: Int) throws -> Self{
        
        var data = RenderData()
        
        //init passes
        for component in content{
            //Compute
            if let computeComponent = component as? Compute{
                data.passes.append(ComputePass(computeComponent, libraryContainer: libraryContainer))
                data.addTextures(newTexs: computeComponent.textures.map{ $0.container })
                try data.createBuffers(buffers: computeComponent.buffers, device: device)
                data.createUniforms(computeComponent.uniforms, device: device)
                
                librarySource += computeComponent.librarySource
                
                if librarySource != ""{
                
                    //arguments for functions
                    let kernel = MetalFunction.compute(computeComponent.kernel)
                    let funcAndArg = FunctionAndArguments(function: kernel,
                                                          arguments: computeComponent.kernelArguments)
                    data.functionsAndArgumentsToAddToMetal
                        .append(funcAndArg)
                }
            }
            //Clear Render
            if let clearRenderComponent = component as? ClearRender{
                data.passes.append(ClearRenderPass(clearRenderComponent))
            }
            //Render
            if let renderComponent = component as? Render{
                data.passes.append(RenderPass(renderComponent, libraryContainer: libraryContainer))
                data.addTextures(newTexs: renderComponent.vertexTextures.map{ $0.container })
                data.addTextures(newTexs: renderComponent.fragTextures.map{ $0.container })
                data.addTextures(newTexs: renderComponent.passColorAttachments.values.map{ $0.texture })
                data.addTextures(newTexs: [renderComponent.passStencilAttachment?.texture])
                try data.createBuffers(buffers: renderComponent.vertexBufs, device: device)
                try data.createBuffers(buffers: renderComponent.fragBufs, device: device)
                data.createUniforms(renderComponent.uniforms, device: device)
                
                let source = renderComponent.librarySource
                let sourceHash = source.hashValue
                if !Self.librarySourceHashes.contains(sourceHash){
                    Self.librarySourceHashes.append(sourceHash)
                    librarySource = source + librarySource
                    
                    //librarySource += renderComponent.librarySource
                    
                    if librarySource != ""{
                        
                        //arguments for functions
                        let vertex = MetalFunction.vertex(renderComponent.vertexFunc)
                        let vertexAndArg = FunctionAndArguments(function: vertex,
                                                                arguments: renderComponent.vertexArguments)
                        data.functionsAndArgumentsToAddToMetal
                            .append(vertexAndArg)
                        
                        let fragment = MetalFunction.fragment(renderComponent.fragmentFunc)
                        let fragAndArg = FunctionAndArguments(function: fragment,
                                                              arguments: renderComponent.fragmentArguments)
                        data.functionsAndArgumentsToAddToMetal
                            .append(fragAndArg)
                    }
                }
                
            }
            //Manual Encode
            if let manualEncodeComponent = component as? ManualEncode{
                data.passes.append(ManualEncodePass(manualEncodeComponent))
            }
            //CPUCompute
            if let cpuComponentComponent = component as? CPUCompute{
                data.passes.append(CPUComputePass(cpuComponentComponent))
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
            //Scale Texture
            if let scaleTextureComponent = component as? ScaleTexture{
                data.addTextures(newTexs: [scaleTextureComponent.inTexture, scaleTextureComponent.outTexture, scaleTextureComponent.inplaceTexture])
                data.passes.append(ScaleTexturePass(scaleTextureComponent))
            }
            //EncodeGroup
            if let encodeGroupComponent = component as? EncodeGroup{
                let groupData = try compile(
                    device: device,
                    pixelFormat: pixelFormat,
                    content: encodeGroupComponent.metalContent,
                    librarySource: &librarySource,
                    helpers: &helpers,
                    libraryContainer: libraryContainer,
                    options: options,
                    context: context,
                    level: level+1
                )
                data.textures.append(contentsOf: groupData.textures)
                let groupPass = EncodeGroupPass(groupData.passes,
                                                repeating: encodeGroupComponent.repeating,
                                                active: encodeGroupComponent.active)
                data.passes.append(groupPass)
                data.functionsAndArgumentsToAddToMetal.append(contentsOf: groupData.functionsAndArgumentsToAddToMetal)
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
                        helpers: buildingBlockComponent.helpers,
                        options: options,
                        context: context
                    )
                    data.append(blockData)
                }else{
                    //compile to shared library
                    let source = buildingBlockComponent.librarySource
                    let sourceHash = source.hashValue
                    if !Self.librarySourceHashes.contains(sourceHash){
                        Self.librarySourceHashes.append(sourceHash)
                        librarySource = source + librarySource
                    }
                    let buildingBlockHelpers = buildingBlockComponent.helpers
                    let helpersHash = buildingBlockHelpers.hashValue
                    if !Self.helpersHashes.contains(helpersHash){
                        Self.helpersHashes.append(helpersHash)
                        helpers += buildingBlockHelpers
                    }
                    
                    let blockData = try compile(
                        device: device,
                        pixelFormat: pixelFormat,
                        content: buildingBlockComponent.metalContent,
                        librarySource: &librarySource,
                        helpers: &helpers,
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
                librarySource = helpers + librarySource
                try parse(library: &librarySource,
                          funcArguments: data.functionsAndArgumentsToAddToMetal)
                
                let libraryPrefix: String
                switch options.libraryPrefix{
                case .`default`: libraryPrefix = kMetalBuilderDefaultLibraryPrefix
                case .custom(let prefix): libraryPrefix = prefix
                }
                librarySource = libraryPrefix + librarySource
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
    
    func createUniforms(_ u: [UniformsContainer], device: MTLDevice){
        _ = u.map{ u in
            u.setup(device: device)
        }
    }
    
    mutating func setViewport(size: CGSize, device: MTLDevice){
        context.setViewportSize(size)
        //update textures
        do{
            if !texturesCreated{
                try createTextures(context: context, device: device)
                texturesCreated = true
            }else{
                try updateTextures(device: device)
            }
        }catch{ print(error) }
    }
    
    func createTextures(context: MetalBuilderRenderingContext, device: MTLDevice) throws{
        //create textures
        for tex in textures{
            do{
                try tex.create(device: device,
                               viewportSize: context.viewportSize,
                               pixelFormat: renderInfo.pixelFormat)
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
                                   pixelFormat: renderInfo.pixelFormat)
                }catch{
                    print(error)
                }
            }
        }
    }
    
    func setupPasses(renderInfo: GlobalRenderInfo) throws{
        //setup passes
        for pass in passes{
            try pass.setup(renderInfo: renderInfo)
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
        
        //librarySourceHashes.append(contentsOf: data.librarySourceHashes)
        
        functionsAndArgumentsToAddToMetal
            .append(contentsOf: data.functionsAndArgumentsToAddToMetal)
        
        //libraryBindings.append(contentsOf: data.libraryBindings)
    }
}
