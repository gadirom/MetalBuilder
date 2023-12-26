
import MetalKit
import SwiftUI

public typealias MBGridScale = (Float, Float, Float)

extension MTLSize{
    mutating func scale(_ scale: MBGridScale){
        width  = Int(ceil(Float(width)*scale.0))
        height = Int(ceil(Float(height)*scale.1))
        depth  = Int(ceil(Float(depth)*scale.2))
    }
}

public typealias ThreadsSourceName = String

public enum IndexType: String{
    case uint = "uint",
    ushort = "ushort"
}
public enum GridFit{
    case fitTexture(MTLTextureContainer, ThreadsSourceName, MBGridScale),
         fitArrayOfTextures(ArrayOfTexturesContainer, ThreadsSourceName, MBGridScale, MetalBinding<Int>),
         fitBuffer(BufferContainer, ThreadsSourceName, MBGridScale),
         size2D(MetalBinding<(Int, Int)>),
         size3D(MetalBinding<(MTLSize)>),
         size1D(MetalBinding<Int>),
         drawable(ThreadsSourceName, MBGridScale)
}

//render time funcs
extension GridFit{
    func gridSize(_ drawable: CAMetalDrawable?) throws -> MTLSize{
        var size: MTLSize
        var gridScale: MBGridScale = (1,1,1)
        switch self{
        case .fitTexture(let container, _, let gScale):
            size = try fitTex(container: container)
            gridScale = gScale
        case .fitArrayOfTextures(let array, _, let gScale, let id):
            let container = array.textures[id.wrappedValue]
            size = try fitTex(container: container)
            gridScale = gScale
        case .size3D(let s):
            size = s.wrappedValue
        case .size2D(let bs):
            let s = bs.wrappedValue
            size = MTLSize(width: s.0, height: s.1, depth: 1)
        case .size1D(let s):
            size = MTLSize(width: s.wrappedValue, height: 1, depth: 1)
        case .drawable: size = MTLSize(width: drawable!.texture.width, height: drawable!.texture.height, depth: 1)
        case .fitBuffer(let buf, _, let gScale):
            size = try fitBuf(buf: buf)
            gridScale = gScale
        }
        
        size.scale(gridScale)
        
        return size
    }
    func fitTex(container: MTLTextureContainer) throws -> MTLSize{
        guard let texture = container.texture
        else{
            throw MetalBuilderComputeError
                .gridFitTextureIsNil("fitTextrure \(container.label ?? "") for threads dispatching for a kernel is nil!")
        }
        return MTLSize(width: texture.width, height: texture.height, depth: texture.depth)
    }
    func fitBuf(buf: BufferContainer) throws -> MTLSize{
        guard let count = buf.count
        else{
            throw MetalBuilderComputeError
                .gridFitNoBuffer("buffer \(String(describing: buf.metalName)) for threads dispatching for a kernel has no count!")
        }
        return MTLSize(width: count, height: 1, depth: 1)
    }
}

//generate code
extension GridFit{
    var gridCheck: String{
        get throws{
            let dim = try threadPositionInGridDim
            return if dim == 1{
            """
            if(gid>=gidCount) return;
            """
            }else{
                if dim == 2{
                """
                if(gid.x>=gidCount.x||gid.y>=gidCount.y) return;
                """
                }else{
                """
                if(gid.x>=gidCount.x||gid.y>=gidCount.y||gid.z>=gidCount.z) return;
                """
                }
            }
        }
    }
    //returns declarations of arguments for compute shader
    func computeKernelArguments(bodyCode: String,
                                indexType: IndexType,
                                gidCountBufferIndex: Int) throws -> String{
        let dim = try threadPositionInGridDim
        let type = if dim>1 { "\(indexType)\(dim)" }
        else { "\(indexType)" }
        var argsArr = computeKernelArgumentsDict
            .compactMap{ key, value in
                if isThereIdentifierInCode(code: bodyCode,
                                           identifier: key){
                    return "\(type) \(key) [[\(value)]]"
                }else{
                    return nil
                }
            }
        argsArr.append("constant \(type)& gidCount [[buffer(\(gidCountBufferIndex))]]")
        return argsArr.joined(separator: ",")
        
        //
        
    }
    var threadPositionInGridDim: Int{
        get throws{
            return switch self {
            case .fitTexture(let mTLTextureContainer, _, let mbGridScale):
                try dimFromTextureType(mTLTextureContainer.descriptor.type,
                                       mbGridScale: mbGridScale,
                                       source: String(describing: mTLTextureContainer))
            case .fitArrayOfTextures(let arrayOfTextures, _, let mbGridScale, _):
                try dimFromTextureType(arrayOfTextures.type,
                                       mbGridScale: mbGridScale,
                                       source: String(describing: arrayOfTextures))
            case .size3D(_):
                3
            case .size2D(_):
                2
            case .size1D(_):
                1
            case .drawable(_, let mbGridScale):
                if mbGridScale.2 > 1{
                    3
                }else{
                    2
                }
            case .fitBuffer(_, _, let mbGridScale):
                if mbGridScale.2 > 1{
                    3
                }else{
                    if mbGridScale.1 > 1{
                        2
                    }else{
                        1
                    }
                }
            }
        }
    }
    func dimFromTextureType(_ type: MTLTextureType?, mbGridScale: MBGridScale, source: String) throws -> Int{
        switch type{
        case    .type1D,
                .typeTextureBuffer,
                .type1DArray:
            if mbGridScale.2 > 1{
                3
            }else{
                if mbGridScale.1 > 1{
                    2
                }else{
                    1
                }
            }
        case    .type2D,
                .type2DArray,
                .type2DMultisample,
                .type2DMultisampleArray:
            if mbGridScale.2 > 1{
                3
            }else{
                2
            }
        case .typeCube:
            2// ???
        case .typeCubeArray:
            2// ???
        case .type3D:
            3
        case nil:
            throw MetalBuilderComputeError
                .gridFitTextureIsNil(source)
        case .some(_):
            throw MetalBuilderComputeError
                .gridFitTextureIsUnknown(source)
        }
    }
}

func isThereIdentifierInCode(code: String, identifier: String) -> Bool{
    let regX = try! Regex("\\b\(identifier)\\b")
    return code.contains(regX)
}

let computeKernelArgumentsDict: [String: String] =
[
    "gid"   : "thread_position_in_grid",
    "tid"   : "thread_position_in_threadgroup",
    "t_gid" : "threadgroup_position_in_grid",
    "tpt"   : "threads_per_threadgroup",
]
