
import SwiftUI
import MetalKit

/// Declares a state for depth and stencil.
@propertyWrapper
public final class MetalDepthStencilState{
    public var wrappedValue: MetalDepthStencilStateContainer
    
    public var projectedValue: MetalDepthStencilState{
        self
    }
    
    public init(wrappedValue: MetalDepthStencilStateContainer){
        self.wrappedValue = wrappedValue
    }
    public init(_ descriptor: MetalDepthStencilDescriptor){
        self.wrappedValue = MetalDepthStencilStateContainer(descriptor: descriptor)
    }
}

extension MetalDepthStencilState{
    public convenience init(label: String? = nil,
                isDepthWriteEnabled: Bool? = true,
                depthCompareFunction: MTLCompareFunction? = nil){
        let descriptor = MetalDepthStencilDescriptor(label: label,
                                                     isDepthWriteEnabled: isDepthWriteEnabled,
                                                     depthCompareFunction: depthCompareFunction)
        self.init(descriptor)
    }
}

public struct MetalDepthStencilDescriptor{
    
    var _label: String?
    var _depthCompareFunction: MTLCompareFunction?
    var _isDepthWriteEnabled: Bool?
    var _frontFaceStencil: MTLStencilDescriptor!
    var _backFaceStencil: MTLStencilDescriptor!
    
    var descriptor: MTLDepthStencilDescriptor{
        let dephDescriptor = MTLDepthStencilDescriptor()
        if let _depthCompareFunction{
            dephDescriptor.depthCompareFunction = _depthCompareFunction
        }
        if let _isDepthWriteEnabled{
            dephDescriptor.isDepthWriteEnabled = _isDepthWriteEnabled
        }
        if let _frontFaceStencil{
            dephDescriptor.frontFaceStencil = _frontFaceStencil
        }
        if let _backFaceStencil{
            dephDescriptor.backFaceStencil = _backFaceStencil
        }
        if let _label{
            dephDescriptor.label = _label
        }
        return dephDescriptor
    }

    public init(label: String? = nil,
                isDepthWriteEnabled: Bool? = true,
                depthCompareFunction: MTLCompareFunction? = nil){
        self._label = label
        self._isDepthWriteEnabled = isDepthWriteEnabled
        self._depthCompareFunction = depthCompareFunction
    }
}
public extension MetalDepthStencilDescriptor{
    func label(_ label: String) -> MetalDepthStencilDescriptor {
        var d = self
        d._label = label
        return d
    }
    func depthCompareFunction(_ function: MTLCompareFunction) -> MetalDepthStencilDescriptor {
        var d = self
        d._depthCompareFunction = function
        return d
    }
    func isDepthWriteEnabled(_ enabled: Bool) -> MetalDepthStencilDescriptor {
        var d = self
        d._isDepthWriteEnabled = enabled
        return d
    }
}

public final class MetalDepthStencilStateContainer {
    var state: MTLDepthStencilState?
    var descriptor: MetalDepthStencilDescriptor!
    
    public init(descriptor: MetalDepthStencilDescriptor) {
        self.descriptor = descriptor
    }
    
    public func create(device: MTLDevice) {
        if state == nil{
            state = device.makeDepthStencilState(descriptor: descriptor.descriptor)
        }
    }
}
