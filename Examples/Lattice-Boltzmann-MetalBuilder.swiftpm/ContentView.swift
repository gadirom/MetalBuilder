import SwiftUI
import MetalBuilder
import MetalKit
import MetalPerformanceShaders

let desc = TextureDescriptor()
    .usage([.shaderRead, .shaderWrite])
    .sizeFromViewport()
    .pixelFormat(.r16Float)

let autoDesc = TextureDescriptor()
    .usage([.shaderRead, .shaderWrite])
    .pixelFormat(.rgba16Float)
    .sizeFromViewport()
    .type(.type2DArray)
    .arrayLength(3)

struct ContentView: View {
    @State var isDrawing = false
    @State var loadTexture = 0
    @State var renderTexture = 0
    @State var obstacleDraw = true
    @State var clearObstacle = 0
    @State var viewCurle = false
    
    let startTime = CFAbsoluteTimeGetCurrent()
    
    @MetalState(metalName: "touchCoord") var touchCoord: simd_float2 = [0,0]
    @MetalState var touchPoint: simd_float2 = [0,0]
    
    @MetalState var drawing = 0
    
    @MetalState var radius: Float = 0
    
    @MetalTexture(autoDesc) var outTexture
    @MetalTexture(autoDesc) var tempTexture
    @MetalTexture(desc) var obstacleTexture
    @MetalTexture(desc) var drawTexture
    
    let autoUniforms = UniformsContainer(
        automataUniformsDescriptor,
        name: "uni"
    )
    
    var body: some View {
        VStack{
            MetalBuilderView(librarySource: librarySource,
                             helpers: "",
                             isDrawing: $isDrawing) { context in
                EncodeGroup{
                    Compute("initialize")
                        .texture(outTexture, argument: .init(type: "float", access: "write", name: "out"))
                        .uniforms(autoUniforms)
                        .bytes(context.$viewportSize)
                        .bytes(context.$time)
                    ManualEncode{device,commandBuffer,_  in
                        
                        loadTexture = 0
                        renderTexture = 1
                    }
                }.repeating($loadTexture)
                EncodeGroup{
                    Compute("clearObstacle")
                        .texture(obstacleTexture, argument: .init(type: "float", access: "write", name: "out"))
                        .uniforms(autoUniforms)
                        .bytes(context.$viewportSize)
                        .bytes(context.$time)
                    ManualEncode{device,commandBuffer,_  in
                        clearObstacle = 0
                    }
                }.repeating($clearObstacle)
                EncodeGroup{
                    ManualEncode{_,_,_  in
                        touchCoord = touchPoint*context.$scaleFactor.wrappedValue
                        //print(time)
                    }
                    
                    EncodeGroup{
                        DrawCircle(context: context,
                                   outTexture: drawTexture,
                                   touchCoord: $touchCoord,
                                   uniforms: autoUniforms)
                        DrawObstacle(context: context,
                                     drawTexture: drawTexture,
                                     outTexture: obstacleTexture,
                                     uniforms: autoUniforms)
                    }.repeating($drawing)
                    Automata(context: context, uniforms: autoUniforms,
                             inTexture: outTexture,
                             outTexture: tempTexture,
                             obstacleTexture: obstacleTexture)
                    AutomataRead(context: context,
                                 outTexture: tempTexture,
                                 obstacleTexture: obstacleTexture,
                                 uniforms: autoUniforms)
                    BlitTexture()
                        .source(tempTexture)
                        .destination(outTexture)
                }.repeating($renderTexture)
            }
             .onResize { _ in
                 loadTexture = 1
                 isDrawing = true
             }
             .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                 .onChanged{ value in
                     touchPoint = [Float(value.location.x),
                                   Float(value.location.y)]
                     drawing = 1
                 }
                 .onEnded{_ in
                     drawing = 0
                 })
            HStack{
                Button {
                    loadTexture = 1
                } label: {
                    Text("reset fluid")
                }
                Button {
                    clearObstacle = 1
                } label: {
                    Text("clear obstacle")
                }
                Group{
                    if obstacleDraw{
                        Text("erase")
                    }else{
                        Text("draw")
                    }
                }
                        .onTapGesture {
                            withAnimation{
                                obstacleDraw.toggle()
                                autoUniforms.setFloat(obstacleDraw ? 1:0, for: "draw")
                            }
                        }
                        .onAppear{
                            obstacleDraw = autoUniforms.getFloat("draw")==1
                        }
                        .transition(.opacity)
                Text("View curle")
                    .background(RoundedRectangle(cornerRadius: 5)
                        .stroke(viewCurle ? .white : .clear)
                                )
                    .onTapGesture {
                        withAnimation{
                            viewCurle.toggle()
                            autoUniforms.setFloat(viewCurle ? 1:0, for: "viewCurl")
                        }
                    }
                    .onAppear{
                        viewCurle = autoUniforms.getFloat("viewCurle")==1
                    }
            }
            UniformsView(autoUniforms)
                .frame(height: 250)
        }
    }
}

let url = Bundle.main.url(forResource: "Sketch_skin", withExtension: "png")!

let librarySource = """
void kernel initialize(uint2 gid[[thread_position_in_grid]]){
            //F
     float4 g0 = float4(1);
     float4 g1 = float4(1);
     float4 g2 = float4(1);

    float2 uv = float2(gid);///float2(viewportSize);
    g0 += uni.rnd*float4(hash(uv+time*.186), hash(uv+time*.54));
    g1 += uni.rnd*float4(hash(uv+time*.64), hash(uv+time*.79));
    g2.r += uni.rnd*hash(uv+time*.35).r;
    g1.r = uni.force;

    out.write(g0, gid, 0);
    out.write(g1, gid, 1);
    out.write(g2, gid, 2);

}
void kernel clearObstacle(uint2 gid[[thread_position_in_grid]]){
    float4 col = float4(0);
    out.write(col, gid);
}
"""
