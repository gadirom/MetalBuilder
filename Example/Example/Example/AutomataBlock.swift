import MetalBuilder
import SwiftUI
import MetalKit

struct AutomataBlock: MetalBuildingBlock{
    var helpers: String = ""
    
    var librarySource: String = ""
    
    let compileOptions: MetalBuilderCompileOptions? = nil
    
    var context: MetalBuilderRenderingContext
    
    @MetalBinding var iterations: Int
    
    var argBuf: ArgumentBuffer
    
    @MetalState(metalName: "from") var from: UInt16 = 0
    @MetalState(metalName: "to") var to: UInt16 = 1
    
//    @MetalState var iter: Int = 0
//    @MetalState var dispatch = false
//    
//    @MetalState var event: MTLEvent!
    
    var metalContent: MetalContent{
        //GPUDispatchAndWait()
        ManualEncode{device,_ in
            //iterations = 2000
            print("run automata for \(iterations) iterations")
//            event = device.makeEvent()
//            iter += 1
//            dispatch = iter%2 == 0
        }
        EncodeGroup(repeating: $iterations.binding){
//            EncodeGroup(active: $dispatch){
//                GPUDispatchAndWait()
//            }
            Compute("autKer")
//                .additionalEncode(.constant({encoder in
//                    encoder.event
//                    encoder.updateFence(fence)
//                }))
//                    if from == 0{
//                        encoder.updateFence(fence)
//                    }else{
//                        encoder.waitForFence(fence)
//                    }
//                }))
                .bytes($from)
                .bytes($to)
//                .texture(tex, argument: .init(type: "float",
//                                              access: "read", name: "in"),
//                                            fitThreads: true)
//                .texture(tex1, argument: .init(type: "float",
//                                               access: "write", name: "out"))
                .argBuffer(argBuf, name: "textures", .init()
                    .arrayOfTextures("textures", usage: [.read, .write],
                                     fitThreadsId: .constant(0),
                                     gridScale: (0.5, 0.5, 1))
                )
            //.uniforms(uniforms)
            //.gidIndexType(.uint)
                .body("""
        
            auto t0 = textures.textures[from];
            auto t1 = textures.textures[to];
        
            float3 c0 = t0.read(gid).rgb;
        
            float3 c1 = t0.read(ushort2(short2(gid)+short2(-1, 0))).rgb;
            float3 c2 = t0.read(ushort2(short2(gid)+short2( 1, 0))).rgb;
            float3 c3 = t0.read(ushort2(short2(gid)+short2( 0,-1)) % ushort2(50000, gidCount.y)).rgb;
            //float3 c4 = t0.read(ushort2(short2(gid)+short2( 0, 1))).rgb;

            float t = 2.;//0.5;
            t1.write(float4((c0+(c1+c2+c3)*t)/(1.+t*3.), 1), gid);
        
            //t1.write(float4(c0,  1), gid);
        
        """)
//            ManualEncode{device, buffer, _ in
//                buffer.encodeSignalEvent(event, value: UInt64(iter))
//                buffer.encodeWaitForEvent(event, value: UInt64(iter))
//                iter += 1
//            }
            
            ManualEncode{_,_ in
                print("from: \(from), to: \(to)")
                from = (from+1)%2
                to = (to+1)%2
            }
//            ManualEncode{device, buffer, _ in
//                buffer.encodeSignalEvent(event, value: UInt64(iter))
//                buffer.encodeWaitForEvent(event, value: UInt64(iter))
//                iter += 1
//            }
        }
        //GPUDispatchAndWait()
    }
}
