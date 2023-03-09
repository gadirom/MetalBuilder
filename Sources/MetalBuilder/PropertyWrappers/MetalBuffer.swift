
import SwiftUI
import MetalKit

/// Declares an MTLBufferContainer state
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
    /// Initalizer of MetalBuffer property wrapper
    ///
    /// - Parameters:
    ///   - count: size of the buffer, i.e. buffer elements count
    ///   - metalType: type that will be used to address this buffer in Metal library code
    ///   - metalName: name that will be used to address this buffer in Metal library code
    /// DISCLAMER!
    /// This initializer allows Swift to synthesize deferred init of the variable
    /// Yet, as of Swift 5.6 it isn't done correctly and it isn't called for initialization of the corresponding property
    /// Thus, any arguments of this init will be ignored if you use it like this:
    /// struct Test{
    ///    @MetalBuffer(metalName: "buffer") var buffer
    /// }
    /// If you init Test like this: test = Test(buffer: buffer)
    /// the 'metalName' argument will be ignored.
    public init(count: Int? = nil,
                metalType: String? = nil,
                metalName: String? = nil){
        self.wrappedValue = MTLBufferContainer<T>(count: count, metalType: metalType, metalName: metalName)
    }
    public init(_ descriptor: BufferDescriptor){
        self.wrappedValue = MTLBufferContainer<T>(count: descriptor.count, metalType: descriptor.metalType, metalName: descriptor.metalName)
    }
}

public struct BufferDescriptor{
    var count: Int?
    var metalType: String?
    var metalName: String?

    public init(count: Int? = nil,
                metalType: String? = nil,
                metalName: String? = nil){
        self.count = count
        self.metalName = metalName
        self.metalType = metalType
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
    
    public override var count: Int?{
        get {
            _count
        }
        set {
            _count = newValue
        }
    }
    
    private var _count: Int?
    
    public override init(count: Int? = nil, metalType: String? = nil, metalName: String? = nil){
        super.init()
        self.metalType = metalType
        self.metalName = metalName
        self._count = count
    }
    
    /// Creates a new buffer for the container
    /// - Parameter device: The GPU device that creates the buffer
    /// - Parameter count: Number of elements in the new buffer. Pass `nil` if you don't want it to be changed.
    ///
    /// Use this method in ManualEncode block if you need to recreate the buffer in the container
    public func create(device: MTLDevice, count: Int? = nil) throws{
        self.device = device
        elementSize = MemoryLayout<T>.stride
        var count = count
        if count == nil {
            count = self.count
        }else{
            self._count = count
        }
        let length = elementSize!*count!
        buffer = device.makeBuffer(length: length)
        if let buffer = buffer{
            pointer = buffer.contents().bindMemory(to: T.self, capacity: length)
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
