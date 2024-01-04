
import SwiftUI
import MetalBuilder
import MetalKit
import MetalPerformanceShaders

import SceneKit

let particleCount = 10000

let vertexIndexCount = particleCount*3

public let resolution : Int = 100 //Resolution of speed randomization, i.e number of possible different speeds for particles

public let sizeOfTrianglesMin : Float = 10
public let sizeOfTrianglesMax : Float = 50

public let speed : Float = 10
public let angSpeed : Float = 0.1

public let isLaplacian = true

struct ContentView: View {
    
    @MetalUniforms(
        UniformsDescriptor(packed: true)
            .float3("color")
            .float("speed", range: 0...10, value: 1)
            .float("mix", range: 0...1, value: 0.5),
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
            .pixelFormatFromDrawable()
            .usage([.shaderRead, .shaderWrite])
            .manual()
            //.sizeFromViewport(scaled: 1)
    ) var scaledTexture
    
    @MetalTexture(
        TextureDescriptor()
            .type(.type2D)
            .pixelFormatFromDrawable()
            .usage([.shaderRead, .shaderWrite])
            //.manual()
            //.sizeFromViewport(scaled: 1)
    ) var outTexture
    
    @MetalTexture(
        TextureDescriptor()
            .type(.type2D)
            //.pixelFormat(.bgra8Unorm)
            .pixelFormatFromDrawable()
            .usage([.renderTarget, .shaderRead, .shaderWrite])
            //.fixedSize([200, 100])
            .sizeFromViewport(scaled: 1)
    ) var targetTexture
    
    
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
    
    var argBufForTextures: ArgumentBuffer{
        .new("texArgBuf", desc: .init()
            .texture(outTexture,
                     argument: .init(type: "float", access: "sample", name: "image"))
            .texture(targetTexture,
                     argument: .init(type: "float", access: "sample", name: "target"))
        )
    }
    
    @ArrayOfTextures(type: .type2D, maxCount: 2,
                     label: "Array of Textures for automata") var autoTexs
    
    var argBufForAutomata: ArgumentBuffer{
        .new("texAuto", desc: .init()
            .arrayTextures(autoTexs, type: "float", access: "read_write", name: "textures")
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
    
    let asyncGroupInfo = AsyncGroupInfo(runOnStartup: true)
    
    @MetalState var readyToSetReady = false
    
    var viewSettings: MetalBuilderViewSettings{
        MetalBuilderViewSettings(depthPixelFormat: nil,
                                 clearDepth: nil,
                                 stencilPixelFormat: nil,
                                 clearColor: nil,
                                 framebufferOnly: false,
                                 preferredFramesPerSecond: 60)
    }
    
    @State var isDrawing = false
    
    @MetalState var scene: SCNScene!
    
    var body: some View {
        VStack{
            MetalBuilderView(isDrawing: $isDrawing,
                             viewSettings: viewSettings){ context in
                EncodeGroup(active: context.$firstFrame){
                    ManualEncode{_,_ in
                        self.scene = createScene()
//                        self.scene.addCustomGeometry(indices: indexBuffer,
//                                                     vertices: vertexBuffer)
                    }
                }
                AsyncBlock(context: context,
                           asyncGroupInfo: asyncGroupInfo,
                           isDrawing: $isDrawing) 
//                {
//                    scaledTexture.texture!.width != Int(context.viewportSize.x) ||
//                    scaledTexture.texture!.height != Int(context.viewportSize.y) || 
//                    iterations != Int(automataIterations)*2
//                }
                   .asyncContent {
                       ManualEncode{device, _ in
                           print("Start running for value: \(automataIterations)")
                           iterations = Int(automataIterations)*2
                           
                           try! createdParticlesBuffer.create(device: device)
                           //createParticles(particlesBuf: createdParticlesBuffer,
                           //                viewportSize: context.viewportSize)
                           
                           try! createdIndexBuffer.create(device: device)
                           createIndices(createdIndexBuffer, count: vertexCount)
       
                           let currentSize = MTLSize(
                               width: Int(context.viewportSize.x),
                               height: Int(context.viewportSize.y),
                               depth: 1)
                           try! scaledTexture.create(device: device,
                                                     mtlSize: currentSize,
                                                     pixelFormat: .bgra8Unorm)
                           
                           print("create scale for currentSize: \(currentSize)")
                           
                       }
                       CreationBlock(context: context, argBuffer: argBufForCreation)
                       ScaleTexture(type: .fit, method: .bilinear)
                           .source(imageTexture)
                           .destination(scaledTexture)
                       GPUDispatchAndWait()
                       ManualEncode{device, passInfo in
                           
                           try! autoTexs.create(textures: [scaledTexture.texture!,
                                                           scaledTexture.texture!],
                                                device: device, commandBuffer: passInfo.getCommandBuffer())
                           //imageTexture.texture = nil
                           //scaledTexture.texture = nil
                       }
                       AutomataBlock(context: context,
                                     iterations: $iterations,
                                     argBuf: argBufForAutomata)
                   }
                   .processResult {
                       ManualEncode{device, _ in
                           particlesBuffer.buffer = createdParticlesBuffer.buffer
                           indexBuffer.buffer = createdIndexBuffer.buffer
                           
//                           self.scene = createScene()
//                           self.scene.addCustomGeometry(indices: indexBuffer,
//                                                        vertices: vertexBuffer)
                           //print("was run for value: \(automataIterations)")
                           
                           let size = scaledTexture.texture!.mtlSize
                           
                           try! outTexture.create(device: device,
                                                  mtlSize: size,
                                                  pixelFormat: .bgra8Unorm)
                           print("create out for currentSize: \(size)")
                       }
                       BlitArrayOfTextures()
                           .source(autoTexs, range: .constant(0...0))
                           .destination(outTexture)
                   }
                EncodeGroup(active: asyncGroupInfo.wasCompleteOnce){
                    ComputeBlock(context: context,
                                 u: uniforms,
                                 argBuffer: argBuffer)
                    Render("renderParticles", indexBuffer: indexBuffer,
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
                        float4 color; //[[flat]];   // - use this flag to disable color interpolation
                        """)
                            .body(
                        """
                        
                        float2 pixelSpacePosition = arg.vertices[vertex_id].position.xy;
                        
                        float2 viewport = float2(viewportSize);
                        
                        out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
                        out.position.xy = pixelSpacePosition / (viewport / 2.0);
                        
                        out.color = arg.vertices[vertex_id].color;
                        """)
                    )
                    .fragment(
                        FragmentShader()
                            .fragmentOut(
                        """
                            float4 color [[color(0)]];
                        """)
                            .body(
                        """
                            out.color = in.color;
                        """)
                    )
                    EncodeGroup{
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
                    }.repeating($n)
                    //                BlitTexture()
                    //                    .source(targetTexture)
//                    AutomataBlock(context: context,
//                                  u: uniforms,
//                                  argBuf: argBufForAutomata)
                    GPUDispatchAndWait()
                    ManualEncode{_,_ in
                        print("frame")
                        self.scene.addCustomGeometry(indices: indexBuffer,
                                                     vertices: vertexBuffer)
                    }
                    SceneKitRenderer(context: context,
                                     scene: $scene)
                    .toTexture(targetTexture)
                    FullScreenQuad(context: context,
                                   fragmentShader: 
                                    
                        FragmentShader()
                            .uniforms(uniforms)
                            .argBuffer(argBufForTextures, name: "textures", .init()
                                .texture("image", usage: .read)
                                .texture("target", usage: .read)
                            )
                            .body("""
                                constexpr sampler s(address::clamp_to_edge, filter::linear);
                                float3 inColor = textures.target.sample(s, in.uv).rgb;
                                float3 imageColor = textures.image.sample(s, in.uv).rgb;
                                float3 color = mix(inColor, imageColor, u.mix);
                                out = float4(color, 1);
                            """)
                    )
                    /*Compute("postprocessKernel")
                        .argBuffer(argBufForTextures, name: "textures", .init()
                            .texture("image", usage: .read)
                            .texture("target", usage: .read)
                        )
                        .drawableTexture(argument: .init(type: "float", access: "write", name: "out"), fitThreads: true)
                        .uniforms(uniforms)
                    //.gidIndexType(.uint)
                    .body("""
                        //uint2 count = uint2(out.get_width(), out.get_height());
                        //if(gid.x>=count.x||id.y>=count.y){ return; }
                        float3 inColor = textures.target.read(gid).rgb;
                        //float2 uv = float2(gid)/float2(gidCount);
                        //constexpr sampler s(address::clamp_to_edge, filter::linear);
                        float3 imageColor = textures.image.read(gid).rgb;
                        float3 color = mix(inColor, imageColor, u.mix);
                        out.write(float4(color, 1), gid);
                    """)*/
                    //let _ = print("compile")
                }
            }
//            .onStartup{ _ in
//                try! asyncGroupInfo.run()
//            }
            .onResize{ _ in
                //if !asyncGroupInfo.busy.wrappedValue{
                    print("run on resize")
                    try! asyncGroupInfo.run()
                //}
            }
            if showUniforms{
                UniformsView(uniforms)
            }
            HStack{
                Button {
                    showUniforms.toggle()
                } label: {
                    Text("Show Uniforms")
                        .foregroundColor(Color.white)
                        .padding()
                        .background(Color.blue)
                }
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
            Slider(value: $automataIterations, in: 1...2000)
                .onChange(of: automataIterations) { newVal in
                    print("run async for value: \(newVal)")
                    try! asyncGroupInfo.run()
                }
            Slider(value: $blurRadius, in: 0...5)
                
            Slider(value: $fDilate, in: 0...10)
                .onChange(of: fDilate) { newValue in
                    dilateSize = Int(fDilate*10)*2+1
                }
            Slider(value: $laplacianBias.binding, in: 0...1)
            Slider(value: $particleScale.binding, in: 0...10)
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
