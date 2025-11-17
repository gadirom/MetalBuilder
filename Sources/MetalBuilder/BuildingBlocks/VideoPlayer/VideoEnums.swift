//
//  VideoEnums.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 16. 11. 2025..
//

import AVFoundation

public struct VideoColorProperties{
    public init(primaries: VideoColorPrimaries,
                transferFunction: VideoTransferFunction,
                matrix: VideoYCbCrMatrix) {
        self.primaries = primaries
        self.transferFunction = transferFunction
        self.matrix = matrix
    }
    
    public var primaries: VideoColorPrimaries
    public var transferFunction: VideoTransferFunction
    public var matrix: VideoYCbCrMatrix
    
    var dict: [String: Any]{
        [
        AVVideoColorPrimariesKey:   primaries.string,
        AVVideoTransferFunctionKey: transferFunction.string,
        AVVideoYCbCrMatrixKey:      matrix.string
        ]
    }
}

public enum VideoColorPrimaries: CaseIterable{
    case p3_d65
    case smpte_c
    case itu_r_2020
    case itu_r_709_2

    public var string: String {
        switch self {
        case .p3_d65:      return AVVideoColorPrimaries_P3_D65
        case .smpte_c:     return AVVideoColorPrimaries_SMPTE_C
        case .itu_r_2020:  return AVVideoColorPrimaries_ITU_R_2020
        case .itu_r_709_2: return AVVideoColorPrimaries_ITU_R_709_2
        }
    }
}

public enum VideoTransferFunction: CaseIterable{
    case linear
    case itu_r_709_2

//    case sRGB // avaialable only on ios 18
//    case smpte_240m_1995 // available only on mac
    case smpte_st_2084_pq
    case itu_r_2100_hlg

    public var string: String {
        switch self {
        case .linear:           AVVideoTransferFunction_Linear
        case .itu_r_709_2:      AVVideoTransferFunction_ITU_R_709_2
//        case .sRGB:            AVVideoTransferFunction_IEC_sRGB
//        case .smpte_240m_1995:  AVVideoTransferFunction_SMPTE_240M_1995
        case .smpte_st_2084_pq: AVVideoTransferFunction_SMPTE_ST_2084_PQ
        case .itu_r_2100_hlg:   AVVideoTransferFunction_ITU_R_2100_HLG
        }
    }
}

public enum VideoYCbCrMatrix: CaseIterable{
    case itu_r_709_2
    case itu_r_601_4
    case itu_r_2020

    public var string: String {
        switch self {
        case .itu_r_709_2: AVVideoYCbCrMatrix_ITU_R_709_2
        case .itu_r_601_4: AVVideoYCbCrMatrix_ITU_R_601_4
        case .itu_r_2020:  AVVideoYCbCrMatrix_ITU_R_2020
        }
    }
}
