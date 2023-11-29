
import SwiftUI
import MetalBuilder
import MetalKit
import MetalPerformanceShaders

let particleCount = 100000

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
            .sizeFromViewport(scaled: 1)
    ) var scaledTexture
    
    @MetalTexture(
        TextureDescriptor()
            .type(.type2D)
            //.pixelFormat(.bgra8Unorm)
            .pixelFormatFromDrawable()
            .usage([.renderTarget, .shaderRead, .shaderWrite])
            //.fixedSize([200, 100])
            .sizeFromViewport(scaled: 1)
    ) var targetTexture
    
    var argBufForTextures: ArgumentBuffer{
        .new("texArgBuf", desc: .init()
            .texture(scaledTexture, argument: .init(type: "float", access: "read", name: "image"))
            .texture(targetTexture, argument: .init(type: "float", access: "read", name: "target"))
        )
    }
    
    @MetalState var blurRadius: Float = 2.5
    @State var fDilate: Float = 3
    @MetalState var dilateSize = 3
    @MetalState var laplacianBias: Float = 0.5
    
    @MetalBuffer<Particle>(BufferDescriptor()
        .count(particleCount)
        .metalName("particles")
        .passAs(.structReference("ParticlesStruct"))
    ) var particlesBuffer
    @MetalBuffer<Vertex>(count: particleCount*3,
                         metalName: "vertices") var vertexBuffer
    
    @MetalBuffer<UInt32>(count: particleCount*3) var indexBuffer
    
    @MetalState var vertexCount = 3 * particleCount
    @MetalState var particleScale: Float = 1
    
    @MetalRenderPassEncoder var renderEncoder
    
    @State var n = 1
    @State var laplacianPasses = 0
    
    @State var showUniforms = false
    
    @State var json: Data?
    
    var viewSettings: MetalBuilderViewSettings{
        MetalBuilderViewSettings(depthPixelFormat: nil,
                                 clearDepth: nil,
                                 stencilPixelFormat: nil,
                                 clearColor: nil,
                                 framebufferOnly: false,
                                 preferredFramesPerSecond: 60)
    }
    
    var body: some View {
        VStack{
            MetalBuilderView(viewSettings: viewSettings){ context in
                ComputeBlock(context: context,
                             particlesBuffer: $particlesBuffer,
                             vertexBuffer: $vertexBuffer,
                             //particleScale: $particleScale,
                             u: uniforms)
                Render(indexBuffer: indexBuffer,
                       indexCount: MetalBinding<Int>.constant(3),
                       instanceCount: MetalBinding<Int>.constant(particleCount))
                    .uniforms(uniforms)//, name: "uni")
                    .indexTypes(instance: .uint, vertex: .uint)
                    //.renderEncoder($renderEncoder, lastPass: true)
                    .toTexture(targetTexture)
                    //.vertexBuf(vertexBuffer, offset: 0)
                    .vertexBytes($particleScale, name: "scale")
                    .vertexBuf(particlesBuffer)
                    .vertexBytes(context.$viewportSize, space: "constant")
                    .vertexShader(
                        VertexShader("vertexShader",
                                  body:"""
                        RasterizerData out;
                    
                        Particle particle = particles.array[instance_id];
                        float size = particle.size*scale;
                        float angle = particle.angle;
                        float2 position = particle.position;
                        float4 color = particle.color;
                        
                        switch(vertex_id){
                        case 0: color = float4(color.rgb, 0.5); break;
                        case 1: color = float4((color.rgb + u.color)/2., 0.5); break;
                        case 2: color = float4(u.color, 1);
                        }

                        float pi = 3.14;

                        float2 scA = sincos2(angle+pi*2/3*float(vertex_id));

                        float2 pixelSpacePosition = position + size*scA;

                        float2 viewport = float2(viewportSize);
                        
                        out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
                        out.position.xy = pixelSpacePosition / (viewport / 2.0);

                        out.color = color;

                        return out;
                    """)
                        .vertexOut(
                    """
                    struct RasterizerData{
                        float4 position [[position]];
                        float4 color; //[[flat]];   // - use this flag to disable color interpolation
                    };
                    """
                        )
                    )
                    .fragmentShader(FragmentShader("fragmentShader",
                                                   fragmentOut:
                    """
                       struct FragmentOut{
                           float4 color [[color(0)]];
                       };
                    """, body:
                    """
                        FragmentOut out;
                        //primitive_id
                        out.color = in.color;
                        return out;
                    """))
//                Render(vertex: "vertexShader", fragment: "fragmentShader", count: vertexCount)
//                    .uniforms(uniforms)//, name: "uni")
//                    .toTexture(targetTexture)
//                    .vertexBuf(vertexBuffer, offset: 0)
//                    .vertexBytes(context.$viewportSize, space: "constant")
                EncodeGroup{
                    EncodeGroup{
                        CPUCompute{ _ in
                            //blurRadius+=0.1
                        }
                        ManualEncode{ [self] device, commandBuffer, drawable in
                            let l = MPSImageLaplacian(device: device)
                            l.bias = laplacianBias
                            l.encode(commandBuffer: commandBuffer, inPlaceTexture: &(targetTexture.texture!), fallbackCopyAllocator: copyAllocator)
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
                ScaleTexture(type: .fit, method: .bilinear)
                    .source(imageTexture)
                    .destination(scaledTexture)
                Compute("postprocessKernel")
                    .argBuffer(argBufForTextures, name: "textures", .init()
                        .texture("image", usage: .read)
                        .texture("target", usage: .read)
                    )
                    //.texture(targetTexture, argument: .init(type: "float", access: "read", name: "in"))
                    //.texture(scaledTexture, argument: .init(type: "float", access: "read", name: "image"))
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
                    """)
                //let _ = print("compile")
            }
            .onResize{ size in
                createParticles(particlesBuf: particlesBuffer,
                                viewportSize: size)
                createIndices(indexBuffer, count: vertexCount)
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
            Slider(value: $blurRadius.binding, in: 0...5)
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

func createParticles(particlesBuf: MTLBufferContainer<Particle>, viewportSize: CGSize){
    
    let x = Float(viewportSize.width)
    let y = Float(viewportSize.height)
    
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
           Particle(color: color,
                    position: [posX, posY],
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
