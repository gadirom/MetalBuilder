
import MetalKit
import SwiftUI

final class LibraryContainer{
    var library: MTLLibrary?
}

struct RenderData{
    
    var argumentsData = ArgumentsData()
    
    var passes: [MetalPass] = []
    
    var asyncPasses: [AsyncGroupPass] = []
    
    var texturesCreated = false

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
        setupFunctions = []
        
        data.argumentsData.createUniforms(device: renderInfo.device)
        
        try data.setupPasses(renderInfo: renderInfo)
        
        try data.setupAsyncPasses(renderInfo: renderInfo, commandQueue: context.commandQueue)
        
        try createBuffers(device: renderInfo.device, withNoArgBufInfo: true)
        
        try data.prerunPasses(renderInfo: renderInfo)
        
        try data.prerunAsyncPasses(renderInfo: renderInfo)
        
        try createBuffers(device: renderInfo.device, withNoArgBufInfo: false)
        
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
                
                let (argData, source) = try computeComponent
                    .setup(supportFamily4: renderInfo.supportsFamily4)
                data.argumentsData.appendContentsExceptFuncArgs(of: argData)
            
                data.passes.append(ComputePass(computeComponent,
                                               libraryContainer: libraryContainer))
                
                let sourceHash = source.hashValue
                if !Self.librarySourceHashes.contains(sourceHash){
                    Self.librarySourceHashes.append(sourceHash)
                    librarySource = source + librarySource
                    
                    if librarySource != ""{
                        
                        //arguments for functions
                        data.argumentsData.funcAndArgs
                            .append(contentsOf: argData.funcAndArgs)
                    }
                }
            }
            //Clear Render
            if let clearRenderComponent = component as? ClearRender{
                data.passes.append(ClearRenderPass(clearRenderComponent))
            }
            //Render
            if var renderComponent = component as? Render{
                var (argData, source) = try renderComponent.setup()
                argData.textures.append(contentsOf: renderComponent.renderableData.usedTextures)
                data.passes.append(
                    RenderPass(renderComponent,
                               libraryContainer: libraryContainer)
                )
                
                data.argumentsData.appendContentsExceptFuncArgs(of: argData)
                
                let sourceHash = source.hashValue
                if !Self.librarySourceHashes.contains(sourceHash){
                    Self.librarySourceHashes.append(sourceHash)
                    librarySource = source + librarySource
                    
                    //librarySource += renderComponent.librarySource
                    
                    if librarySource != ""{
                        //arguments for functions
                        data.argumentsData.funcAndArgs
                            .append(contentsOf: argData.funcAndArgs)
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
            //GPUDispatchAndWait
            if component is GPUDispatchAndWait{
                data.passes.append(GPUDispatchAndWaitPass())
            }
            //MPSUnary
            if let mpsUnaryComponent = component as? MPSUnary{
                data.argumentsData.addTextures(newTexs: [mpsUnaryComponent.inTexture, mpsUnaryComponent.outTexture])
                data.passes.append(MPSUnaryPass(mpsUnaryComponent))
            }
            //Blit Texture
            if let blitTextureComponent = component as? BlitTexture{
                data.argumentsData.addTextures(newTexs: [blitTextureComponent.inTexture, blitTextureComponent.outTexture])
                data.passes.append(BlitTexturePass(blitTextureComponent))
            }
            //Blit Array of Textures
            if let blitArrayOfTexturesComponent = component as? BlitArrayOfTextures{
                data.passes.append(BlitArrayOfTexturesPass(blitArrayOfTexturesComponent))
            }
            //Blit Buffer
            if let blitBufferComponent = component as? BlitBuffer{
                data.argumentsData.addBuffers(newBuffs: [blitBufferComponent.inBuffer!,
                                           blitBufferComponent.outBuffer!])
                data.passes.append(BlitBufferPass(blitBufferComponent))
            }
            //Scale Texture
            if let scaleTextureComponent = component as? ScaleTexture{
                data.argumentsData.addTextures(newTexs: [scaleTextureComponent.inTexture, scaleTextureComponent.outTexture, scaleTextureComponent.inplaceTexture])
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
                
                let groupPass = EncodeGroupPass(
                    groupData.passes,
                    repeating: encodeGroupComponent.repeating.binding,
                    active: encodeGroupComponent.active.binding
                )
                
                data.passes.append(groupPass)
                
                data.append(groupData, noPasses: true)
//                data.functionsAndArgumentsToAddToMetal.append(contentsOf: groupData.functionsAndArgumentsToAddToMetal)
//                data.setupFunctions.append(contentsOf: groupData.setupFunctions)
//                data.startupFunctions.append(contentsOf: groupData.startupFunctions)
            }
            //AsyncGroup
            if let asyncGroupComponent = component as? AsyncGroup{
                let groupData = try compile(
                    renderInfo: renderInfo,
                    content: asyncGroupComponent.metalContent,
                    librarySource: &librarySource,
                    helpers: &helpers,
                    libraryContainer: libraryContainer,
                    options: options,
                    context: context,
                    level: level+1
                )
                
//                data.addTextures(newTexs: groupData.textures)
//                data.addBuffers(newBuffs: groupData.buffers)
                
                let asyncGroupPass = AsyncGroupPass(groupData.passes, info: asyncGroupComponent.info)
                data.asyncPasses.append(asyncGroupPass)
                data.startupFunctions.append(asyncGroupComponent.info.startup)
                
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
                librarySource = data.argumentsData.argBufDecls + librarySource
                librarySource = helpers + librarySource
                
                try parse(library: &librarySource,
                          funcArguments: data.argumentsData.funcAndArgs)
                
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
    
    mutating func setViewport(size: CGSize, device: MTLDevice){
        context.setViewportSize(size)
        //update textures
        do{
            if !texturesCreated{
                try createTextures(device: device)
                texturesCreated = true
                
                for sf in startupFunctions{
                    //DispatchQueue.main.async{
                        sf(device)
                    //}
                }
                startupFunctions = []
                
            }else{
                try updateTextures(device: device)
            }
        }catch{ fatalError(error.localizedDescription) }
    }
    
    func createTextures(device: MTLDevice) throws{
        //create textures
        for tex in argumentsData.textures{
            try tex.initialize(device: device,
                               viewportSize: context.viewportSize,
                               pixelFormat: renderInfo.pixelFormat)
        }
    }

    func createBuffers(device: MTLDevice, withNoArgBufInfo: Bool) throws{
        for buf in argumentsData.buffers{
            if buf.bContainer.argBufferInfo.argBuffers.isEmpty == withNoArgBufInfo{
                try buf.create(device: device)
            }
        }
    }
    
    func updateTextures(device: MTLDevice) throws{
        for tex in argumentsData.textures{
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
    func setupAsyncPasses(renderInfo: GlobalRenderInfo, commandQueue: MTLCommandQueue) throws{
        //setup passes
        for pass in asyncPasses{
            try pass.setup(renderInfo: renderInfo)
        }
    }
    func prerunPasses(renderInfo: GlobalRenderInfo) throws{
        //prerun passes
        for pass in passes{
            try pass.prerun(renderInfo: renderInfo)
        }
    }
    func prerunAsyncPasses(renderInfo: GlobalRenderInfo) throws{
        //prerun passes
        for pass in asyncPasses{
            try pass.prerun(renderInfo: renderInfo)
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
        
        asyncPasses.append(contentsOf: data.asyncPasses)
        
        argumentsData.appendContents(of: data.argumentsData)
    
        setupFunctions.append(contentsOf: data.setupFunctions)
        startupFunctions.append(contentsOf: data.startupFunctions)
    }
}
