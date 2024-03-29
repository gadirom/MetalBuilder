
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
    
    //Byffers a stored here and created after setupFunction of all the building blocks are done,
    //since there some properties of containers might be changed in a setupFunction.
    var buffers: [BufferProtocol] = []
    
    var texturesCreated = false
    
    var functionsAndArgumentsToAddToMetal: [FunctionAndArguments] = []

    var renderInfo: GlobalRenderInfo!
    
    var context: MetalBuilderRenderingContext!
    
    //functions that run before texture and buffer creation, but after compilation
    //this is needed if you correct descriptors depending on renderableData
    //that can be changed via chaining modifiers and is not available in initializers of Building Blocks
    var setupFunctions: [()->()] = []
    //functions that run after textures and buffers are created but before rendering
    //(actually, when rendering is already started since some textures cannot be created before you get a drawable)
    var startupFunctions: [(MTLDevice)->()] = []
    
    //hold hashes for librarySources of BuildingBlocks, Render and Compute components to eliminate dublicates
    static var librarySourceHashes: [Int] = []
    //hold hashes for helpers of BuildingBlocks to eliminate dublicates when librarySource is embedded into the components that constitute the given BuildingBlock
    static var helpersHashes: [Int] = []
    
    init(){}
    
    init(from renderingContent: MetalBuilderContent,
         librarySource: String,
         helpers: String,
         options: MetalBuilderCompileOptions,
         context: MetalBuilderRenderingContext,
         renderInfo: GlobalRenderInfo,
         setupFunction: (()->())?,
         startupFunction: ((MTLDevice)->())?) throws{
        
        self.context = context
        //self.device = device
        self.renderInfo = renderInfo
        
        let content = renderingContent(context)
        //var libraryContainer = LibraryContainer()
        
        let data = try Self.compile(renderInfo: renderInfo,
                                    content: content,
                                    librarySource: librarySource,
                                    helpers: helpers,
                                    options: options,
                                    context: context)
        self.append(data)
        
        Self.librarySourceHashes = []
        Self.helpersHashes = []
        
        if let setupFunction = setupFunction{
            self.setupFunctions.append(setupFunction)
        }
        if let startupFunction = startupFunction{
            self.startupFunctions.append(startupFunction)
        }
        
        for sf in setupFunctions {
            sf()
        }
        
        try createBuffers(device: renderInfo.device)
        
        try data.setupPasses(renderInfo: renderInfo)
    }
    
    static func compile(renderInfo: GlobalRenderInfo,
                        content: MetalContent,
                        librarySource: String,
                        helpers: String,
                        options: MetalBuilderCompileOptions,
                        context: MetalBuilderRenderingContext) throws -> Self{
        
        var librarySource = librarySource
        var helpers = helpers
        let libraryContainer = LibraryContainer()
        
        return try compile(renderInfo: renderInfo,
                           content: content,
                           librarySource: &librarySource,
                           helpers: &helpers,
                           libraryContainer: libraryContainer,
                           options: options,
                           context: context,
                           level: 0)
    }
    
    static func compile(renderInfo: GlobalRenderInfo,
                        content: MetalContent,
                        librarySource: inout String,
                        helpers: inout String,
                        libraryContainer: LibraryContainer,
                        options: MetalBuilderCompileOptions,
                        context: MetalBuilderRenderingContext,
                        level: Int) throws -> Self{
        
        var data = RenderData()
        
        let device = renderInfo.device
        
        //init passes
        for component in content{
            //Compute
            if var computeComponent = component as? Compute{
                
                try computeComponent.setup(supportFamily4: renderInfo.supportsFamily4)
                data.passes.append(ComputePass(computeComponent, libraryContainer: libraryContainer))
                data.addTextures(newTexs: computeComponent.textures.map{ $0.container })
                data.addBuffers(newBuffs: computeComponent.buffers)
                data.createUniforms(computeComponent.uniforms, device: device)
                
                let source = computeComponent.librarySource
                let sourceHash = source.hashValue
                if !Self.librarySourceHashes.contains(sourceHash){
                    Self.librarySourceHashes.append(sourceHash)
                    librarySource = source + librarySource
                    
                    if librarySource != ""{
                        
                        //arguments for functions
                        let kernel = MetalFunction.compute(computeComponent.kernel)
                        let funcAndArg = FunctionAndArguments(function: kernel,
                                                              arguments: computeComponent.kernelArguments)
                        data.functionsAndArgumentsToAddToMetal
                            .append(funcAndArg)
                    }
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
                
                data.addTextures(newTexs: renderComponent.renderableData.passColorAttachments.values.map{ $0.texture })
                data.addTextures(newTexs: [renderComponent.renderableData.passStencilAttachment?.texture])
                data.addBuffers(newBuffs: renderComponent.vertexBufs)
                data.addBuffers(newBuffs: renderComponent.fragBufs)
                
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
                data.addBuffers(newBuffs: [blitBufferComponent.inBuffer!,
                                           blitBufferComponent.outBuffer!])
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
                    renderInfo: renderInfo,
                    content: encodeGroupComponent.metalContent,
                    librarySource: &librarySource,
                    helpers: &helpers,
                    libraryContainer: libraryContainer,
                    options: options,
                    context: context,
                    level: level+1
                )
                
//                data.addTextures(newTexs: groupData.textures)
//                data.addBuffers(newBuffs: groupData.buffers)
                
                let groupPass = EncodeGroupPass(groupData.passes,
                                                repeating: encodeGroupComponent.repeating,
                                                active: encodeGroupComponent.active)
                data.passes.append(groupPass)
                
                data.append(groupData, noPasses: true)
//                data.functionsAndArgumentsToAddToMetal.append(contentsOf: groupData.functionsAndArgumentsToAddToMetal)
//                data.setupFunctions.append(contentsOf: groupData.setupFunctions)
//                data.startupFunctions.append(contentsOf: groupData.startupFunctions)
            }
            //Building Block
            if let buildingBlockComponent = component as? MetalBuildingBlock{
                let blockData: RenderData
                if let options = buildingBlockComponent.compileOptions{
                    //compile to it's own library
                    blockData = try compile(
                        renderInfo: renderInfo,
                        content: buildingBlockComponent.metalContent,
                        librarySource: buildingBlockComponent.librarySource,
                        helpers: buildingBlockComponent.helpers,
                        options: options,
                        context: context
                    )
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
                    
                    blockData = try compile(
                        renderInfo: renderInfo,
                        content: buildingBlockComponent.metalContent,
                        librarySource: &librarySource,
                        helpers: &helpers,
                        libraryContainer: libraryContainer,
                        options: options,
                        context: context,
                        level: level+1
                    )
                }
                
                data.append(blockData)
                data.setupFunctions.append(buildingBlockComponent.setup)
                data.startupFunctions.append(buildingBlockComponent.startup)
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
    
    //adds only unique buffers
    mutating func addBuffers(newBuffs: [BufferProtocol?]){
        let newBuffers = newBuffs.compactMap{ $0 }
            .filter{ newBuffer in
                !buffers.contains{ oldBuffer in
                    newBuffer === oldBuffer
                }
            }
        buffers.append(contentsOf: newBuffers)
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
                
                for sf in startupFunctions{
                    DispatchQueue.main.async{
                        sf(device)
                    }
                }
                
            }else{
                try updateTextures(device: device)
            }
        }catch{ print(error) }
    }
    
    func createTextures(context: MetalBuilderRenderingContext, device: MTLDevice) throws{
        //create textures
        for tex in textures{
            try tex.initialize(device: device,
                               viewportSize: context.viewportSize,
                               pixelFormat: renderInfo.pixelFormat)
        }
    }

    func createBuffers(device: MTLDevice) throws{
        for buf in buffers{
            try buf.create(device: device)
        }
    }
    
    func updateTextures(device: MTLDevice) throws{
        for tex in textures{
            if case .fromViewport = tex.descriptor.size{
                try tex.create(device: device,
                               viewportSize: context.viewportSize,
                               pixelFormat: renderInfo.pixelFormat)
            }
        }
    }
    
    func setupPasses(renderInfo: GlobalRenderInfo) throws{
        //setup passes
        for pass in passes{
            try pass.setup(renderInfo: renderInfo)
        }
    }
    
    static func addSwiftTypes(from buffers: [BufferProtocol], to swiftTypes: inout [SwiftTypeToMetal]){
        for buf in buffers {
            if let type = buf.swiftTypeToMetal{
                swiftTypes.append(type)
            }
        }
    }
    
    mutating func append(_ data: RenderData, noPasses: Bool = false){
        if !noPasses{
            passes.append(contentsOf: data.passes)
        }
        
        addTextures(newTexs: data.textures)
        addBuffers(newBuffs: data.buffers)
        
        functionsAndArgumentsToAddToMetal
            .append(contentsOf: data.functionsAndArgumentsToAddToMetal)
    
        setupFunctions.append(contentsOf: data.setupFunctions)
        startupFunctions.append(contentsOf: data.startupFunctions)
    }
}
