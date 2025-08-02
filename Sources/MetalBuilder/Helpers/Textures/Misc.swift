//
//  Misc.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 2. 6. 2025..
//

import MetalKit

public func swapTextures(_ tex1: MTLTextureContainer, _ tex2: MTLTextureContainer){
    let temp = tex1.texture
    tex1.texture = tex2.texture
    tex2.texture = temp
}
