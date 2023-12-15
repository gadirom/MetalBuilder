import MetalBuilder
import SwiftUI
import MetalKit

struct CreationBlock: MetalBuildingBlock{
    
    let compileOptions: MetalBuilderCompileOptions? = nil
    
    var context: MetalBuilderRenderingContext
    
    var argBuffer: ArgumentBuffer
    
    var metalContent: MetalContent{
            Compute("particleFunction")
                .argBuffer(argBuffer, name: "arg", UseResources()
                    .buffer("particles", usage: .write, fitThreads: true)
                    .buffer("indices", usage: .write)
                )
                .gidIndexType(.uint)
                //.buffer(particlesBuffer, space: "device", fitThreads: true)
                .bytes(context.$viewportSize)
                //.bytes($particleScale, name: "scale")
                .uniforms(u)
                .body("""
                //int gidi = int(gid);
                Particle particle;
                particle.position = position;
                
                arg.particles.array[gid] = particle;
                arg.indices.array[gid] = particle;

                """)
        }
   
    let helpers: String = ""
    
    let librarySource = ""

}
