import MetalKit

struct UseResource{
    let resourceType: ResourceType
    let usage: MTLResourceUsage
    let stages: MTLRenderStages?
    let name: String
}
public struct UseResources{
    var array: [UseResource] = []
    var gridFitBasedOnResourceID: Int?
    var gridScale: MBGridScale?
    public init(){
    }
}
public extension UseResources{
    func texture(_ name: String, usage: MTLResourceUsage, stages: MTLRenderStages?) -> Self {
        var ur = self
        ur.array.append(
            UseResource(resourceType: .texture,
                        usage: usage, stages: stages,
                        name: name)
        )
        return ur
    }
    func texture(_ name: String, usage: MTLResourceUsage,
                 fitThreads: Bool=false, gridScale: MBGridScale?=nil) -> Self {
        var ur = self
        do{
            if fitThreads == true || gridScale != nil{
                if gridFitBasedOnResourceID != nil{
                    throw ArgumentBufferError.gridFitSetTwice(name)
                }else{
                    ur.gridFitBasedOnResourceID = array.count
                    ur.gridScale = gridScale
                }
            }
            ur = ur.texture(name, usage: usage, stages: nil)
        }catch{
            fatalError(error.localizedDescription)
        }
        return ur
    }
    func buffer(_ name: String, usage: MTLResourceUsage, stages: MTLRenderStages?) -> Self {
        var ur = self
        ur.array.append(
            UseResource(resourceType: .buffer,
                        usage: usage, stages: stages,
                        name: name)
        )
        return ur
    }
    func buffer(_ name: String, usage: MTLResourceUsage,
                fitThreads: Bool=false, gridScale: MBGridScale?=nil) -> Self {
        var ur = self
        do{
            if fitThreads == true || gridScale != nil{
                if gridFitBasedOnResourceID != nil{
                    throw ArgumentBufferError.gridFitSetTwice(name)
                }else{
                    ur.gridFitBasedOnResourceID = array.count
                    ur.gridScale = gridScale
                }
            }
            ur = ur.buffer(name, usage: usage, stages: nil)
        }catch{
            print(error.localizedDescription)
        }
        return ur
    }
}

struct UseResourceEntry: Equatable{
    static func == (lhs: UseResourceEntry, rhs: UseResourceEntry) -> Bool {
        lhs.resource === rhs.resource
    }
    
    let resource: MTLResourceContainer
    let usage: MTLResourceUsage
    let stages: MTLRenderStages?
}

class ResourcesUsages{
    var allResourcesUsages: [UseResourceEntry] = [] // agglomerated resources used by kernel/draw call
    
    func addToKernel(argBuf: ArgumentBuffer, resources: UseResources) -> GridFit?{
        var gridfit: GridFit?=nil
        do{
            _ = try resources.array.enumerated()
                .map{ id, ur in
                    guard let resource = argBuf.descriptor.arguments
                        .first(where: { $0.1.name == ur.name })?.0
                    else{
                        throw ArgumentBufferError.argumentBufferNoArgumentWithName(argBuf.name, ur.name)
                    }
                    let entry = UseResourceEntry(resource: resource.resource,
                                                 usage: ur.usage,
                                                 stages: ur.stages)
                    allResourcesUsages.appendUnique(entry)
                    let threadsSourceName = argBuf.name+"."+ur.name
                    if id == resources.gridFitBasedOnResourceID{
                        if let tex = resource.resource as? MTLTextureContainer{
                            gridfit = .fitTexture(tex, threadsSourceName, resources.gridScale ?? (1,1,1))
                        }
                        if let buf = resource.resource as? BufferContainer{
                            gridfit = .fitBuffer(buf, threadsSourceName, resources.gridScale ?? (1,1,1))
                        }
                    }
                }
            
        }catch{
            fatalError(error.localizedDescription) 
        }
        return gridfit
    }
    func addEntry(resource: MTLResourceContainer, use: UseResource){
        if let existingEntry = allResourcesUsages.enumerated().first(where: { resource===$0.element.resource }){
            var stages: MTLRenderStages?
            if existingEntry.element.stages != nil{
                stages = existingEntry.element.stages!.union(use.stages ?? .init())
            }
            let usage = existingEntry.element.usage.union(use.usage)
            allResourcesUsages[existingEntry.offset] = UseResourceEntry(resource: resource,
                                                                        usage: usage,
                                                                        stages: stages)
            
        }else{
            allResourcesUsages.append(
                UseResourceEntry(resource: resource,
                                 usage: use.usage,
                                 stages: use.stages))
        }
    }
}
