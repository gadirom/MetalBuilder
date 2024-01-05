
import SwiftUI
import MetalBuilder
import MetalKit
import MetalPerformanceShaders

import SceneKit

let particlesInOneFrame = 1000

let particleCount = maxTexCount*particlesInOneFrame

let vertexIndexCount = particleCount*3

public let resolution : Int = 100 //Resolution of speed randomization, i.e number of possible different speeds for particles

public let sizeOfTrianglesMin : Float = 10
public let sizeOfTrianglesMax : Float = 50

public let speed : Float = 10
public let angSpeed : Float = 0.1

public let isLaplacian = true

let maxTexCount = 10

var uniDesc: UniformsDescriptor{
    var uniDesc = UniformsDescriptor(packed: true)
        .float3("color")
        .float("speed", range: 0...10, value: 1)
        .float("angSpeed", range: 0...1, value: 1)
        .float("size", range: 0...100, value: 0.5)
        .float("texId", range: 0...Float(maxTexCount-1), value: 0.0)
        .float("texId1", range: 0...Float(maxTexCount-1), value: 0.5)
        .float("mix", range: 0...1, value: 0.5)
        .float("cMix", range: 0...1, value: 0.5)
    LightRenderer.addUniforms(&uniDesc)
    return uniDesc
}

struct ContentView: View {
    
    @MetalUniforms(
        uniDesc,
        type: "Uniform",
        name: "u"
    ) var uniforms
    
    @MetalTexture(
        TextureDescriptor()
            .usage([.shaderRead]),
        fromImage: .init(url: Bundle.main.url(forResource: "testImage", withExtension: "png")!,
                         origin: .flippedVertically)
    ) var imageTexture
    
    @MetalTexture(
        TextureDescriptor()
            .type(.type2D)
            .pixelFormat(.r16Float)
            .usage([.shaderRead, .shaderWrite])
            //.manual()
            //.sizeFromViewport(scaled: 1)
    ) var monoTexture
    
    @MetalTexture(
        TextureDescriptor()
            .type(.type2D)
            .pixelFormat(.r16Float)
            .usage([.shaderRead, .shaderWrite])
            //.manual()
            //.sizeFromViewport(scaled: 1)
    ) var sdf
    
    @MetalTexture(
        TextureDescriptor()
            .type(.type2D)
            //.pixelFormat(.bgra8Unorm)
            .pixelFormatFromDrawable()
            .usage([.renderTarget, .shaderRead, .shaderWrite])
            //.fixedSize([200, 100])
            .sizeFromViewport(scaled: 1)
            .manual()
    ) var targetTexture
    
    @MetalTexture(
        TextureDescriptor()
            .type(.type2D)
            //.pixelFormat(.bgra8Unorm)
            .pixelFormatFromDrawable()
            .usage([.renderTarget, .shaderRead, .shaderWrite])
            //.fixedSize([200, 100])
            .sizeFromViewport(scaled: 1)
            .manual()
    ) var previousTexture
    
    
    var argBufForCreation: ArgumentBuffer{
        .new("argBufForCreation", desc:
            ArgumentBufferDescriptor()
                .buffer(createdParticlesBuffer, name: "particles", space: "device")
                .buffer(createdIndexBuffer, name: "indices", space: "device")
        )
    }
    var argBuffer: ArgumentBuffer{
        .new("argBuffer", desc:
            ArgumentBufferDescriptor("MyArgBuffer")
                .buffer(particlesBuffer, name: "particles", space: "device")
                .buffer(vertexBuffer, name: "vertices", space: "device")
        )
    }
    
//    var argBufForTextures: ArgumentBuffer{
//        .new("texArgBuf", desc: .init()
//            .texture(outTexture,
//                     argument: .init(type: "float", access: "sample", name: "image"))
//            .texture(targetTexture,
//                     argument: .init(type: "float", access: "sample", name: "target"))
//        )
//    }
    
    @ArrayOfTextures(type: .type2D, maxCount: maxTexCount,
                     label: "Array of Textures for automata") var autoTexs
    
    var argBufForAutomata: ArgumentBuffer{
        .new("texAuto", desc: .init()
            .arrayTextures(autoTexs, type: "float", access: "sample", name: "textures")
        )
    }
    
    @State var blurRadius: Float = 2.5
    @State var automataIterations: Float = 10
    @State var fDilate: Float = 3
    @MetalState var dilateSize = 3
    @MetalState var laplacianBias: Float = 0.5
    
    @MetalState var iterations: Int = 2000
    
    @MetalBuffer<Particle>(
        BufferDescriptor()
        .count(particleCount)
        .metalName("particles")
        .passAs(.structReference("ParticlesStruct"))
    ) var createdParticlesBuffer
    
    @MetalBuffer<Particle>(
        BufferDescriptor()
        .count(particleCount)
        .metalName("particles")
        .passAs(.structReference("ParticlesStruct"))
    ) var particlesBuffer
    
    @MetalBuffer<Vertex>(count: particleCount*3,
                         metalName: "vertices") var vertexBuffer
    
    @MetalBuffer<UInt32>(count: particleCount*3) var indexBuffer
    @MetalBuffer<UInt32>(BufferDescriptor()
                         .count(particleCount*3)
                         .passAs(.structReference("IndexStruct"))) var createdIndexBuffer
    
    @MetalState var vertexCount = 3 * particleCount
    @MetalState var particleScale: Float = 1
    
    @MetalRenderPassEncoder var renderEncoder
    
    @State var n = 1
    @State var laplacianPasses = 0
    
    @State var showUniforms = false
    
    @State var json: Data?
    
    let asyncGroupInfo = AsyncGroupInfo(runOnStartup: false)
    
    var viewSettings: MetalBuilderViewSettings{
        MetalBuilderViewSettings(depthPixelFormat: nil,
                                 clearDepth: nil,
                                 stencilPixelFormat: nil,
                                 clearColor: nil,
                                 framebufferOnly: false,
                                 preferredFramesPerSecond: 60)
    }
    
    @State var isDrawing = true
    
    @MetalState var texCount = maxTexCount
    @MetalState var currentTex = 0
    @MetalState var shiftTex: UInt32 = 0
    
    @MetalState var indexOffset = 0
    
    @MetalState var pixelFormat: MTLPixelFormat? = nil
    
    @MetalState var event: MTLEvent!
    
    var body: some View {
        ZStack{
            MetalBuilderView(isDrawing: $isDrawing,
                             viewSettings: viewSettings){ context in
                EncodeGroup(active: context.$firstFrame){
                    ManualEncode{device,info in
                        event = device.makeEvent()
                        uniforms.setFloat(0, for: "texId")
                        uniforms.setFloat(0, for: "texId1")
                        pixelFormat = info.drawable!.texture.pixelFormat
                        try! asyncGroupInfo.run()
                    }
                }
                AsyncBlock(context: context,
                           asyncGroupInfo: asyncGroupInfo) 

                   .asyncContent {
                       ManualEncode{device, _ in
                           print("Start running for value: \(automataIterations)")
                           iterations = Int(automataIterations)*2
                           
                           try! createdParticlesBuffer.create(device: device)
                           //createParticles(particlesBuf: createdParticlesBuffer,
                           //                viewportSize: context.viewportSize)
                           
                           try! createdIndexBuffer.create(device: device)
                           createIndices(createdIndexBuffer, count: vertexCount)
       
                           
                       }
                       CreationBlock(context: context, argBuffer: argBufForCreation)
                       
                       ManualEncode{device, passInfo in
                           
                           
                           let sizes = (0..<texCount)
                               .map{ _ in
                                   MTLSize(width: Int.random(in: 10...2000),
                                           height: Int.random(in: 10...2000),
                                           depth: 1)
                               }
                           
                           try! autoTexs.create(sizes: sizes,
                                                pixelFormat: pixelFormat!,
                                                usage: [.renderTarget, 
                                                        .shaderRead,
                                                        .shaderWrite],
                                                device: device, 
                                                hazardTracking: .tracked)
                       }
                   }
                   .processResult {
                       ManualEncode{device, _ in
                           particlesBuffer.buffer = createdParticlesBuffer.buffer
                           indexBuffer.buffer = createdIndexBuffer.buffer
                           
                       }
                   }
                EncodeGroup(active: asyncGroupInfo.wasCompleteOnce){
                    ComputeBlock(context: context,
                                 u: uniforms,
                                 argBuffer: argBuffer)
                    EncodeGroup(repeating: texCount){
                        ManualEncode{_,passInfo in
//                            let buffer = passInfo.getCommandBuffer()
//                            
//                            buffer.encodeSignalEvent(
//                                event, value: UInt64(currentTex*2)
//                            )
//                            buffer.encodeWaitForEvent(
//                                event, value: UInt64(currentTex*2)
//                            )
                            
                            targetTexture.texture = autoTexs[currentTex]!.texture!
                            
                            let shiftTex = (
                                (currentTex+texCount - 1) % texCount
                            )
                            
                            previousTexture.texture = autoTexs[shiftTex]!.texture!
                            
                            indexOffset = currentTex*particlesInOneFrame*3*4
                            currentTex = (currentTex + 1) % texCount
                            
                        }
                        
                        Render("renderParticles", indexBuffer: indexBuffer,
                               indexOffset: $indexOffset, 
                               indexCount: MetalBinding<Int>.constant(particlesInOneFrame*3))
                        //.uniforms(uniforms)//, name: "uni")
                        .indexTypes(instance: .uint, vertex: .uint)
                        //.renderEncoder($renderEncoder, lastPass: true)
                        .toTexture(targetTexture)
                        //.vertexBuf(vertexBuffer, offset: 0)
                        .vertex(
                            VertexShader()
                                .argBuffer(argBuffer, name: "arg", UseResources()
                                    .buffer("vertices", usage: [.read])
                                )
                            //.bytes($particleScale, name: "scale")
                            //.buffer(particlesBuffer)
                                .bytes(context.$viewportSize)
                                .uniforms(uniforms)
                                
                                .vertexOut(
                        """
                        float4 position [[position]];
                        float4 color;
                        float2 uv;
                        """)
                                .body(
                        """
                        
                        float2 pixelSpacePosition = arg.vertices[vertex_id].position.xy;
                        
                        float2 viewport = float2(viewportSize);
                        
                        out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
                        out.position.xy = pixelSpacePosition / (viewport / 2.0);
                        
                        out.color = arg.vertices[vertex_id].color;
                        out.uv = arg.vertices[vertex_id].uv;
                        """)
                        )
                        .fragment(
                            FragmentShader()
                                .uniforms(uniforms)
                                .texture(previousTexture, argument: .init(type: "float", access: "sample", name: "target"))
                                .bytes($shiftTex, name: "shiftId")
                                .fragmentOut(
                        """
                            float4 color [[color(0)]];
                        """)
                                .body(
                        """
                        constexpr sampler s(address::clamp_to_edge, filter::linear);
                        float3 inColor = in.color.rgb;
                        uint id = shiftId;
                        float3 texColor = target.sample(s, in.uv).rgb;
                        float3 color = mix(inColor, texColor, u.mix);
                        out.color = float4(color, 1);
                        """)
                        )
//                        ManualEncode{_,passInfo in
//                            let buffer = passInfo.getCommandBuffer()
//                            
//                            let e = currentTex>0 ? currentTex-1 : texCount-1
//                            
//                            buffer.encodeSignalEvent(
//                                event, value: UInt64(e*2+1)
//                            )
//                            buffer.encodeWaitForEvent(
//                                event, value: UInt64(e*2+1)
//                            )
//                        }
                        
                        //GPUDispatchAndWait()
//                        Compute("postprocessKernel")
//                            .texture(targetTexture, argument: .init(type: "float", access: "read_write", name: "target"), fitThreads: true)
//                            .uniforms(uniforms)
//                        .body("""
//                            float3 inColor = target.read(gid).rgb;
//                            
//                            float3 color = mix(inColor, float3(0.5), u.mix);
//                            target.write(float4(color, 1), gid);
//                        """)
                    }
                   /* EncodeGroup{
                        EncodeGroup{
//                            CPUCompute{ _ in
//                                //blurRadius+=0.1
//                            }
                            ManualEncode{ device, passInfo in
                                print("draw frame")
                                let l = MPSImageLaplacian(device: device)
                                l.bias = laplacianBias
                                l.encode(commandBuffer: passInfo.getCommandBuffer(),
                                         inPlaceTexture: &(targetTexture.texture!), fallbackCopyAllocator: copyAllocator)
                            }
                        }.repeating($laplacianPasses)
                        //Seems that Laplacian can't be initialized through superclass init!
                        //                MPSUnary{MPSImageLaplacian(device: $0)}
                        //                    .source(targetTexture)
                        //                    .value($laplacianBias, for: "bias")
                        MPSUnary{MPSImageAreaMax(device: $0,
                                                 kernelWidth: dilateSize, kernelHeight: dilateSize)}
                        .source(targetTexture)
                        MPSUnary{ [self] in MPSImageGaussianBlur(device: $0, sigma: blurRadius)}
                            .source(targetTexture)
                        //.toDrawable()
                    }.repeating($n)*/
                    /*Render("renderPart", indexBuffer: indexBuffer,
                           indexCount: MetalBinding<Int>.constant(vertexIndexCount))
                    //.uniforms(uniforms)//, name: "uni")
                    .indexTypes(instance: .uint, vertex: .uint)
                    //.renderEncoder($renderEncoder, lastPass: true)
                    .toTexture(targetTexture)
                    //.vertexBuf(vertexBuffer, offset: 0)
                    .vertex(
                        VertexShader()
                            .argBuffer(argBuffer, name: "arg", UseResources()
                                .buffer("vertices", usage: [.read])
                            )
                        //.bytes($particleScale, name: "scale")
                        //.buffer(particlesBuffer)
                            .bytes(context.$viewportSize)
                            .uniforms(uniforms)
                            .vertexOut(
                    """
                    float4 position [[position]];
                    float2 uv;
                    float4 color; //[[flat]];   // - use this flag to disable color interpolation
                    """)
                            .body(
                    """
                    
                    float2 pixelSpacePosition = arg.vertices[vertex_id].position.xy;
                    
                    float2 viewport = float2(viewportSize);
                    
                    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
                    out.position.xy = pixelSpacePosition / (viewport / 2.0);
                    out.uv = arg.vertices[vertex_id].uv;
                    
                    out.color = arg.vertices[vertex_id].color;
                    """)
                    )
                    .fragment(
                        FragmentShader()
                            .uniforms(uniforms)
                            .argBuffer(argBufForAutomata, name: "textures", .init()
                                .arrayOfTextures("textures", usage: .read)
                            )
                            .fragmentOut(
                    """
                        float4 color [[color(0)]];
                    """)
                            .body(
                    """
                        constexpr sampler s(address::clamp_to_edge, filter::linear);
                        float3 inColor = in.color.rgb;
                        uint id = uint(u.texId);
                        float3 texColor = textures.textures[id].sample(s, in.uv).rgb;
                        float3 color = mix(inColor, texColor, 0.5);
                        out.color = float4(color, 1);
                    """)
                    )*/
//                    ManualEncode{_,passInfo in
//                        let id = Int(uniforms.getFloat("texId1")!)
//                        targetTexture.texture = autoTexs[id]!.texture
//                        
//                        let buffer = passInfo.getCommandBuffer()
//                        buffer.encodeSignalEvent(
//                            event, value: UInt64(texCount*2)
//                        )
//                        buffer.encodeWaitForEvent(
//                            event, value: UInt64(texCount*2)
//                        )
//                    }
//                    MPSUnary{MPSImageAreaMax(device: $0,
//                                             kernelWidth: dilateSize,
//                                             kernelHeight: dilateSize)}
//                    .source(targetTexture)
                    /*EncodeGroup(repeating: $laplacianPasses){
                        ManualEncode{ device, passInfo in
                            //print("draw frame")
                            let l = MPSImageLaplacian(device: device)
                            l.bias = laplacianBias
                            l.encode(commandBuffer: passInfo.getCommandBuffer(),
                                     inPlaceTexture: &(targetTexture.texture!), fallbackCopyAllocator: copyAllocator)
                        }
                    }*/
                    ManualEncode{_,passInfo in
                        let id = Int(uniforms.getFloat("texId")!)
                        targetTexture.texture = autoTexs[id]!.texture
                        
                        let id1 = Int(uniforms.getFloat("texId1")!)
                        previousTexture.texture = autoTexs[id1]!.texture
                        
//                        let buffer = passInfo.getCommandBuffer()
//                        buffer.encodeSignalEvent(
//                            event, value: UInt64(texCount*2+1)
//                        )
//                        buffer.encodeWaitForEvent(
//                            event, value: UInt64(texCount*2+1)
//                        )
                    }
                    
                    FullScreenQuad(context: context,
                                   fragmentShader:
                        FragmentShader()
                            .uniforms(uniforms)
                            .argBuffer(argBufForAutomata, name: "textures", .init()
                                .arrayOfTextures("textures", usage: .read)
                            )
//                            .texture(targetTexture, argument: .init(type: "float", access: "sample", name: "target"))
                            .body("""
                                constexpr sampler s(address::clamp_to_edge, filter::linear);
                                float3 inColor = textures.textures[uint(u.texId)].sample(s, in.uv).rgb;
                                                        
                                out = float4(inColor, 1);
                            """)
                    ).toTexture(targetTexture)
                    
                    Compute("copyToMono")
                        .texture(targetTexture, argument: .init(type: "float", access: "sample", name: "in"))
                        .texture(monoTexture, argument: .init(type: "float", access: "write", name: "out"), fitThreads: true)
                       
//                        .uniforms(uniforms)
                    .body("""
                        constexpr sampler s(address::clamp_to_edge, filter::linear);
                        float2 uv = float2(gid)/float2(gidCount);
                        float3 c = in.sample(s, uv).rgb;
                        float d = length(c)>1. ? 1. : 0.;
                        out.write(float4(d, 0, 0, 1), gid);
                    """)
                    
                    EncodeGroup(repeating: $laplacianPasses){
                        MPSUnary{MPSImageAreaMax(device: $0,
                                             kernelWidth: dilateSize,
                                             kernelHeight: dilateSize)}
                            .source(monoTexture)
                            .value(.init(get: {Float(dilateSize)}, set: {_ in}), for: "kernelWidth")
                            .value(.init(get: {Float(dilateSize)}, set: {_ in}), for: "kernelHeight")
                        ManualEncode{ device, passInfo in
                            //print("draw frame")
                            let l = MPSImageLaplacian(device: device)
                            l.bias = 1
                            l.encode(commandBuffer: passInfo.getCommandBuffer(),
                                     inPlaceTexture: &(monoTexture.texture!),
                                     fallbackCopyAllocator: copyAllocator)
//                            l.encode(commandBuffer: passInfo.getCommandBuffer(),
//                                     sourceTexture: targetTexture.texture!,
//                                     destinationTexture: monoTexture.texture!)
                        }
                    }
                    
                    SDF(context: context,
                        monoTexture: monoTexture,
                        sdf: sdf)
                    LightRenderer(context: context,
                                  sdfTexture: sdf,
                                  colorTexture: targetTexture,
                                  uniforms: uniforms)
//                    Compute("postprocessKernel")
//                        .texture(monoTexture, argument: .init(type: "float", access: "sample", name: "sdfTex"))
//                        .texture(targetTexture, argument: .init(type: "float", access: "sample", name: "in"))
//                        .drawableTexture(argument: .init(type: "float", access: "write", name: "out"), fitThreads: true)
//                        .uniforms(uniforms)
//                    //.gidIndexType(.uint)
//                    .body("""
//                        constexpr sampler s(address::clamp_to_edge, filter::linear);
//                        float2 uv = float2(gid)/float2(gidCount);
//                        float sdf = sdfTex.sample(s, uv).r;
//                        float3 c = in.sample(s, uv).rgb;
//                        float3 color = c*pow(mix(float3(1), float3(sdf*10.+0.5), u.cMix), 100.);
//                        color = sdf;
//                        out.write(float4(color, 1), gid);
//                    """)
                    //let _ = print("compile")
                }
            }
//            .onStartup{ _ in
//                try! asyncGroupInfo.run()
//            }
            .onResize{ _ in
                //if !asyncGroupInfo.busy.wrappedValue{
                   // print("run on resize")
//                    try! asyncGroupInfo.run()
                //}
            }
            if showUniforms{
                ScrollView{
                    UniformsView(uniforms)
                    HStack{
                        
                        Spacer()
                        Button {
                            self.json = uniforms.json
                        } label: {
                            Text("Save Uniforms")
                                .foregroundColor(Color.white)
                                .padding()
                                .background(Color.blue)
                        }
                        
                        Button {
                            if let json = json {
                                showUniforms = false
                                uniforms.import(json: json)
                                DispatchQueue.main.asyncAfter(deadline: .now()+0.01) {
                                    showUniforms = true
                                }
                            }
                        } label: {
                            Text("Load Uniforms")
                                .foregroundColor(Color.white)
                                .padding()
                                .background(Color.blue)
                        }

                    }
        //            Slider(value: $visibleTex, in: 1...Float(texCount))
        //                .onChange(of: automataIterations) { newVal in
        //                    print("currentTex: \(newVal)")
        //                }
                    //Slider(value: $blurRadius, in: 0...5)
                        
                    Slider(value: $fDilate, in: 0...10)
                        .onChange(of: fDilate) { newValue in
                            dilateSize = Int(fDilate*10)*2+1
                        }
                    HStack{
                        Stepper("Number of passes for effects: \(n)") {
                            n += 1
                        } onDecrement: {
                            if n>0{
                                n -= 1
                            }
                        }
                        Stepper("Number of passes for laplacian: \(laplacianPasses)") {
                            laplacianPasses += 1
                        } onDecrement: {
                            if laplacianPasses>0{
                                laplacianPasses -= 1
                            }
                        }
                    }.padding([.trailing], 100)
                }
            }
            
            HStack{
                Spacer()
                VStack{
                    Spacer()
                    Button {
                        showUniforms.toggle()
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(Color.white)
                            .padding()
                        //.background(Color.blue)
                    }
                }
            }
        }
    }
}

func createIndices(_ buf: MTLBufferContainer<UInt32>, count: Int){
    for id in 0..<count{
        buf.pointer![id] = UInt32(id)
    }
}

func createParticles(particlesBuf: MTLBufferContainer<Particle>, viewportSize: simd_uint2){
    
    let x = Float(viewportSize.x)
    let y = Float(viewportSize.y)
    
    for i in 0..<particleCount{
        let red: Float = Float(Int.random(in: 0..<resolution))/Float(resolution)
        let green: Float = Float(Int.random(in: 0..<resolution))/Float(resolution)
        let blue: Float = Float(Int.random(in: 0..<resolution))/Float(resolution)
        
        let veloX = (green - 0.5) * speed
        let veloY = (blue - 0.5) * speed
        
        let size = sizeOfTrianglesMin * (1 - red) + sizeOfTrianglesMax * red
        
        let angle = blue
        
        let posX = Float(arc4random_uniform(UInt32(x))) - x/2
        let posY = Float(arc4random_uniform(UInt32(y))) - y/2
        
        let color = simd_float4(red, green, blue, 1)
        
        let angvelo = Float.random(in: -1..<1) * angSpeed
        
        particlesBuf.pointer![i] =
        Particle(position: [posX, posY],
                 color: color,
                 velocity: [veloX, veloY],
                 size: size,
                 angle: angle, angvelo: angvelo)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
