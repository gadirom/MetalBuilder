
import SwiftUI
import MetalBuilder
import MetalKit
import MetalPerformanceShaders

let particleCount = 10000

public let resolution : Int = 100 //Resolution of speed randomization, i.e number of possible different speeds for particles

public let sizeOfTrianglesMin : Float = 10
public let sizeOfTrianglesMax : Float = 50

public let speed : Float = 10
public let angSpeed : Float = 0.1

public let isLaplacian = true

public let bkgColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)

let desc = UniformsDescriptor()
    .float("size", range: (0...0.1), value: 0.05)
    .float3("color")
    .float4("color4")
    .float("position", range: -200...200)
    .float("op")

struct ContentView: View {
    
    @State var u = UniformsContainer(
        desc, type: "Unif"
    )
    
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
    
    @MetalState var vertexCount = 3 * particleCount
    @MetalState var particleScale: Float = 1
    
    @State var isDrawing = false
    @State var n = 1
    @State var laplacianPasses = 0
    
//    @MetalState var mSize = MTLSize(width: particleCount, height: 1, depth: 1)
//    @MetalState var viewport = MTLViewport(originX: 0.0, originY: 0.0, width: 100, height: 100, znear: 0.0, zfar: 1.0)
    
    var body: some View {
        VStack{
            MetalBuilderView(librarySource: renderFunctions, isDrawing: $isDrawing){ context in
                ComputeBlock(context: context,
                             particlesBuffer: $particlesBuffer,
                             vertexBuffer: $vertexBuffer,
                             particleScale: $particleScale)
                Render(vertex: "vertexShader", fragment: "fragmentShader")
                    .toTexture(targetTexture)
                    .vertexBuf(vertexBuffer, offset: 0)
                    .vertexBytes(context.$viewportSize, space: "constant")
                    .primitives(count: vertexCount)
                EncodeGroup{
                    EncodeGroup{
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
                if isDrawing {return}
                createParticles(particlesBuf: particlesBuffer,
                                viewportSize: size)
                isDrawing = true
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
