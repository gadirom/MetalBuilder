//
//  ResourceManager.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 29. 1. 2026..
//

import MetalKit

//@MainActor
public class ResourceManager{
    protocol Entry{}
    var resources: [String: [(Entry, Any)]] = [:]
    
    var texturesToAddToArrayOfTextures: [(ArrayOfTexturesContainer, [MTLTextureContainer])] = []
}
extension ResourceManager{
    func setup(){
        for tForAOT in texturesToAddToArrayOfTextures{
            tForAOT.0.addTextures(containers: tForAOT.1)
        }
        texturesToAddToArrayOfTextures = []
    }
}
//resources
extension ResourceManager{
    nonisolated(unsafe) static let shared = ResourceManager()
    
    static func registerTexture(group: String?,
                                texture: MTLTextureContainer,
                                argumentBuffers: [(ArgumentBuffer, MetalTextureArgument)]?){
        if let group{
            registerResource(group: group, resource: texture, additionalData: "")
        }
        
        for (argBuf, argument) in argumentBuffers ?? []{
            argBuf.descriptor = argBuf.descriptor
                .texture(texture, argument: argument)
            
            //print("added texture: \(texture.label), group: \(group) to argBuf: \(argBuf.name), \(Unmanaged.passUnretained(argBuf).toOpaque())")
            
        }
    }
    static func registerArrayOfTextures(
        type: MTLTextureType,
        groups: [(String, TextureDescriptor)]?,
        aot: ArrayOfTexturesContainer,
        argumentBuffers: [(ArgumentBuffer, MetalTextureArgument)]?){
        
        var textures: [MTLTextureContainer] = []
        if let groups{
            for group in groups{
                textures.append(.init(group.1.type(type)))
                registerResource(group: group.0, resource: textures.last!, additionalData: "")
            }
        }
            
        //aot.addTextures(containers: textures)
            shared.texturesToAddToArrayOfTextures
                .append((aot, textures))
        
        for (argBuf, argument) in argumentBuffers ?? []{
            argBuf.descriptor = argBuf.descriptor
                .arrayOfTextures(aot,
                                 type: argument.type,
                                 access: argument.access,
                                 name: argument.name)
            
            //print("added texture: \(texture.label), group: \(group) to argBuf: \(argBuf.name), \(Unmanaged.passUnretained(argBuf).toOpaque())")
            
        }
        
    }
    
    static func registerResource(group: String, resource: Entry, additionalData: Any){
        let resources = shared.resources[group] ?? []
        shared.resources[group] = resources + [(resource, additionalData)]
    }
}

//creation
public extension ResourceManager{
    static func createTextures(group: String, mtlSize: MTLSize, device: MTLDevice) throws{
        
        guard let resources = shared.resources[group]
        else{ return }
        
        for resource in resources{
            switch resource.0{
            case let texture as MTLTextureContainer:
                try texture.create(device: device,
                                   mtlSize: mtlSize,
                                   arrayLength: texture.descriptor.arrayLength)
//            case let arrayOfTextures as ArrayOfTexturesContainer:
                    
                    
                    
//                    device: device,
//                                           mtlSize: mtlSize,
//                                           arrayLength: texture.descriptor.arrayLength)
            default: break
            }
            
        }
    }
}
