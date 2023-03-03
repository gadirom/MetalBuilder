
import SwiftUI
import MetalBuilder
import MetalKit
import MetalPerformanceShaders

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
            .float("speed", range: 0...10, value: 1),
        type: "Uniform",
        name: "u"
    ) var uniforms
    
    @MetalTexture(
        TextureDescriptor()
            .type(.type2D)
            //.pixelFormat(.bgra8Unorm)
            .pixelFormatFromDrawable()
            .usage([.renderTarget, .shaderRead, .shaderWrite])
            //.fixedSize([200, 100])
            .sizeFromViewport(scaled: 1)
    ) var targetTexture
    
    @MetalState var blurRadius: Float = 2.5
    @State var fDilate: Float = 3
    @MetalState var dilateSize = 3
    @MetalState var laplacianBias: Float = 0.5
    
    @MetalBuffer<Particle>(BufferDescriptor()
        .count(particleCount)
        .metalName("particles")) var particlesBuffer
    @MetalBuffer<Vertex>(count: particleCount*3,
                         metalName: "vertices") var vertexBuffer
    
    @MetalBuffer<UInt32>(count: particleCount*3) var indexBuffer
    
    @MetalState var vertexCount = 3 * particleCount
    @MetalState var particleScale: Float = 1
    
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
                             particleScale: $particleScale,
                             u: uniforms)
                Render(indexBuffer: indexBuffer,
                       indexCount: MetalBinding<Int>.constant(vertexIndexCount))
                    .uniforms(uniforms)//, name: "uni")
                    .toTexture(targetTexture)
                    .vertexBuf(vertexBuffer, offset: 0)
                    .vertexBytes(context.$viewportSize, space: "constant")
                    .vertexShader(VertexShader("vertexShader",
                                  vertexOut:
                    """
                    struct RasterizerData{
                        float4 position [[position]];
                        float4 color; //[[flat]];   // - use this flag to disable color interpolation
                    };
                    """,
                                  body:"""
                        RasterizerData out;

                        float2 pixelSpacePosition = vertices[vertex_id].position.xy;

                        float2 viewport = float2(viewportSize);
                        
                        out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
                        out.position.xy = pixelSpacePosition / (viewport / 2.0);

                        out.color = vertices[vertex_id].color;

                        return out;
                    """))
                    .fragmentShader(FragmentShader("fragmentShader", body:
                    """
                        return in.color;
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
                BlitTexture()
                    .source(targetTexture)
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
