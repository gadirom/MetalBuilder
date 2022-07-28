
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

struct Particle{
    var color: simd_float4
    var position: simd_float2
    var velocity: simd_float2
    var size: Float
    var angle: Float
    var angvelo: Float
}

struct Vertex
{
    var position: simd_float2
    var color: simd_float4
}

struct ContentView: View {
    
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
    
    @MetalBuffer<Particle>(count: particleCount,
                           metalType: "Particle",
                           metalName: "particles") var particlesBuffer
    @MetalBuffer<Vertex>(count: particleCount*3,
                         metalType: "Vertex",
                         metalName: "vertices") var vertexBuffer
    
    @MetalState var vertexCount = 3 * particleCount
    @MetalState var particleScale: Float = 1
    
    @MetalState var isDrawing = false
//    @MetalState var mSize = MTLSize(width: particleCount, height: 1, depth: 1)
//    @MetalState var viewport = MTLViewport(originX: 0.0, originY: 0.0, width: 100, height: 100, znear: 0.0, zfar: 1.0)
    
    var body: some View {
        VStack{
            MetalBuilderView(librarySource: metalFunctions, isDrawing: $isDrawing){ viewportSize in
                Compute("particleFunction")
                    .buffer(particlesBuffer, offset: 0, space: "device")
                    .buffer(vertexBuffer, offset: 0, space: "device")
                    .bytes(viewportSize,
                           argument: .init(space: "constant", type: "uint2",
                                           name: "viewport", index: 2))
                    .bytes($particleScale,
                           argument: .init(space: "constant", type: "float",
                                           name: "scale", index: 3))
                    .threadsFromBuffer(0)
                    //.grid(size: $mSize)
                Render(vertex: "vertexShader", fragment: "fragmentShader")
                    .toTexture(targetTexture)
                    .vertexBuf(vertexBuffer, offset: 0)
                    .vertexBytes(viewportSize,
                           argument: .init(space: "constant", type: "uint2",
                                           name: "viewport", index: 2))
                    .primitives(count: vertexCount)
                CPUCode{ [self] device, commandBuffer, drawable in
                    let l = MPSImageLaplacian(device: device)
                    l.bias = laplacianBias
                    l.encode(commandBuffer: commandBuffer, inPlaceTexture: &(targetTexture.texture!), fallbackCopyAllocator: copyAllocator)
                }
                //Seems that Laplacian can't be modified through superclass init!
//                MPSUnary{MPSImageLaplacian(device: $0)}
//                    .source(targetTexture)
//                    .value($laplacianBias, for: "bias")
                MPSUnary{MPSImageAreaMax(device: $0,
                                         kernelWidth: dilateSize, kernelHeight: dilateSize)}
                    .source(targetTexture)
                MPSUnary{ [self] in MPSImageGaussianBlur(device: $0, sigma: blurRadius)}
                    .source(targetTexture)
                    .toDrawable()
                
                //let _ = print("compile")
            }
            .onResize{ size in
                if isDrawing {return}
                createParticles(particlesBuf: particlesBuffer,
                                viewportSize: size)
                isDrawing = true
            }
            Slider(value: $blurRadius, in: 0...100)
            Slider(value: $fDilate, in: 0...10)
                .onChange(of: fDilate) { newValue in
                    dilateSize = Int(fDilate*10)*2+1
                }
            Slider(value: $laplacianBias, in: 0...1)
            Slider(value: $particleScale, in: 0...10)
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
