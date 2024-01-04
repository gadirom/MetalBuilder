import MetalBuilder
import SwiftUI
import MetalKit

struct CreationBlock: MetalBuildingBlock{
    
    let compileOptions: MetalBuilderCompileOptions? = nil
    
    var context: MetalBuilderRenderingContext
    
    var argBuffer: ArgumentBuffer
    
    var metalContent: MetalContent{
            Compute("create")
                .argBuffer(argBuffer, name: "arg", UseResources()
                    .buffer("particles", usage: .write, fitThreads: true)
                    .buffer("indices", usage: .write)
                )
                .gidIndexType(.uint)
                .bytes(context.$viewportSize)
                .body("""
                //int gidi = int(gid);
                Particle particle;
                
                float2 vSize = float2(viewportSize);
                float fid = float(gid);//float(gidCount);
                   
                particle.color = float4(hash3(fid), 1);
                
                particle.velocity = (hash3(fid+2.).xy - 0.5) * 10.0f;
                
                float sizeOfTrianglesMin = 10.;
                float sizeOfTrianglesMax = 50.;
                float angSpeed = 0.5;
                
                float h = hash(fid+4.);
                
                particle.size = sizeOfTrianglesMin * (1 - h) + sizeOfTrianglesMax * h;
                
                particle.angle = h;
                
                particle.position.xy = (hash3(fid+49.).xy-0.5)*vSize;
                
                particle.angvelo = (hash(fid+9.)-0.5) * angSpeed;
                
                arg.particles.array[gid] = particle;
                arg.indices.array[gid] = gid;

                """)
        }
    
    //from here https://www.shadertoy.com/view/DdyyDD
    let helpers: String = """

    float hash(float p)
    {
        p = fract(p * .1031);
        p *= p + 33.33;
        p *= p + p;
        return fract(p);
    }
    float3 hash3(float p)
    {
       float3 p3 = fract(float3(p) * float3(.1031, .1030, .0973));
       p3 += dot(p3, p3.yzx+33.33);
       return fract((p3.xxy+p3.yzz)*p3.zyx);
    }
    """
    
    let librarySource = ""

}
