
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

typealias ThreadsSourceName = String

public enum IndexType: String{
    case uint = "uint",
    ushort = "ushort"
}
enum GridFit{
    case fitTexture(MTLTextureContainer, ThreadsSourceName, MBGridScale),
         size2D(MetalBinding<(Int, Int)>),
         size3D(MetalBinding<(MTLSize)>),
         size1D(MetalBinding<Int>),
         drawable(ThreadsSourceName, MBGridScale),
         buffer(BufferContainer, ThreadsSourceName, MBGridScale)
}
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
                switch mTLTextureContainer.texture?.textureType {
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
                    throw MetalBuilderComputeError.gridFitTextureIsNil(String(describing:  mTLTextureContainer))
                case .some(_):
                    throw MetalBuilderComputeError.gridFitTextureIsUnknown(String(describing:  mTLTextureContainer))
                }
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
            case .buffer(_, _, let mbGridScale):
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
