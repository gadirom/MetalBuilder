
import SwiftUI
import MetalKit

/// Declares a state for a MTLBuffer object
///
/// metalType and metalName - supposed type and name for the buffer in MSL code
@propertyWrapper
public final class MetalBuffer<T>{
    public var wrappedValue: MTLBufferContainer<T>
    
    public var projectedValue: MetalBuffer<T>{
        self
    }
    
    public init(wrappedValue: MTLBufferContainer<T>){
        self.wrappedValue = wrappedValue
    }
    /// Creates an instance of MetalBuffer property wrapper.
    /// - Parameters:
    ///   - count: size of the buffer, i.e. buffer elements count.
    ///   - metalType: type that will be used to address this buffer in Metal library code.
    ///   - metalName: name that will be used to address this buffer in Metal library code.
    ///   - options: buffer options.
    ///   - fromArray: an array to copy elements from it to the buffer or `nil` to init the buffer with zeroes.
    public init(count: Int? = nil,
                metalType: String? = nil,
                metalName: String? = nil,
                options: MTLResourceOptions = .init(),
                fromArray: [T]? = nil){
        self.wrappedValue = MTLBufferContainer<T>(count: count,
                                                  metalType: metalType,
                                                  metalName: metalName,
                                                  options: options)
    }
    /// Creates an instance of MetalBuffer property wrapper.
    /// - Parameters:
    ///   - descriptor: descriptor of the buffer to be created.
    ///   - fromArray: an array to copy elements from it to the buffer or `nil` to init the buffer with zeroes.
    public init(_ descriptor: BufferDescriptor, fromArray: [T]? = nil){
        self.wrappedValue = MTLBufferContainer<T>(count: descriptor.count,
                                                  metalType: descriptor.metalType,
                                                  metalName: descriptor.metalName,
                                                  options: descriptor.bufferOptions)
    }
}

public struct BufferDescriptor{
    var count: Int?
    var metalType: String?
    var metalName: String?
    
    var bufferOptions: MTLResourceOptions = .init()

    public init(count: Int? = nil,
                metalType: String? = nil,
                metalName: String? = nil,
                options: MTLResourceOptions = .init()){
        self.count = count
        self.metalName = metalName
        self.metalType = metalType
        
        self.bufferOptions = options
    }
}
public extension BufferDescriptor{
    func count(_ n: Int) -> BufferDescriptor {
        var d = self
        d.count = n
        return d
    }
    func metalName(_ name: String) -> BufferDescriptor {
        var d = self
        d.metalName = name
        return d
    }
    func metalType(_ type: String) -> BufferDescriptor {
        var d = self
        d.metalType = type
        return d
    }
    func options(_ options: MTLResourceOptions) -> BufferDescriptor {
        var d = self
        d.bufferOptions = options
        return d
    }
}

enum MetalBuilderBufferError: Error {
case bufferNotCreated
}

public class BufferContainer{
    
    public var buffer: MTLBuffer?
    
    public var count: Int? { 0 }
    
    public var elementSize: Int?
    
    public var metalType: String?
    public var metalName: String?
    
    init(count: Int? = nil, metalType: String? = nil, metalName: String? = nil) {
        self.metalType = metalType
        self.metalName = metalName
    }
}

/// Container class for MTLBuffer
///
/// You can access it's content on CPU through 'pointer'
public final class MTLBufferContainer<T>: BufferContainer{

    public var pointer: UnsafeMutablePointer<T>?
    
    weak var device: MTLDevice?
    
    public var bufferOptions: MTLResourceOptions = .init()
    
    var fromArray: [T]?
    
    public override var count: Int?{
        get {
            _count
        }
        set {
            _count = newValue
        }
    }
    
    private var _count: Int?
    
    public init(count: Int? = nil, metalType: String? = nil, metalName: String? = nil,
                options: MTLResourceOptions = .init(),
                fromArray: [T]? = nil){
        super.init()
        self.metalType = metalType
        self.metalName = metalName
        self._count = count
        
        self.bufferOptions = options
        
        self.fromArray = fromArray
    }
    
    /// Creates a new buffer for the container.
    /// - Parameters:
    ///   - device: The GPU device that creates the buffer.
    ///   - count: Number of elements in the new buffer. Pass `nil` if you don't want it to be changed.
    ///   - fromArray: an array to copy elements from it to the buffer or `nil` to init the buffer with zeroes.
    ///
    /// Use this method in ManualEncode block if you need to recreate the buffer in the container
    public func create(device: MTLDevice, count: Int? = nil, fromArray: [T]? = nil) throws{
        self.device = device
        elementSize = MemoryLayout<T>.stride
        var count = count
        if count == nil {
            count = self.count
        }else{
            self._count = count
        }
        let length = elementSize!*count!
        if let fromArray{
            buffer = device.makeBuffer(bytes: fromArray, length: length, options: bufferOptions)
        }else if let fromArray = self.fromArray{
            buffer = device.makeBuffer(bytes: fromArray, length: length, options: bufferOptions)
            self.fromArray = nil
        }else{
            buffer = device.makeBuffer(length: length, options: bufferOptions)
        }
        
        let cpuAccessible = ((bufferOptions.rawValue & MTLResourceOptions.storageModeShared.rawValue) != 0) ||
                            ((bufferOptions.rawValue & MTLResourceOptions.cpuCacheModeWriteCombined.rawValue) != 0) ||
                            (bufferOptions == .init()) // Seems like the empty option means "shared"
        
        if let buffer = buffer{
            //create the pointer to the buffer only if its created with a storage mode that allows to acces it from CPU
            if cpuAccessible{
                pointer = buffer.contents().bindMemory(to: T.self, capacity: length)
            }
        }else{
            throw MetalBuilderBufferError
                .bufferNotCreated
        }
    }
}
//load and store data
public extension MTLBufferContainer{
    func getData(count: Int? = nil) -> Data{
        var count = count
        if count == nil{
            count = self.count
        }
        let length = elementSize!*count!
        let data = Data(bytes: buffer!.contents(), count: length)
        return data
    }
    
    func load(data: Data, count: Int? = nil){
        var count = count
        if count == nil{
            count = self.count
        }
        let length = elementSize!*count!
        data.withUnsafeBytes{ bts in
            buffer = device!.makeBuffer(bytes: bts.baseAddress!, length: length)
            if let buffer = buffer{
                pointer = buffer.contents().bindMemory(to: T.self, capacity: length)
            }
        }
    }
}
