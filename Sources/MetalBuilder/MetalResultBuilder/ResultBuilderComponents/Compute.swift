
import MetalKit
import SwiftUI

public typealias AdditionalEncodeClosureForCompute = (MTLComputeCommandEncoder)->()
public typealias AdditionalPiplineSetupClosureForCompute = (MTLComputePipelineState, MTLLibrary)->()
public typealias PiplineSetupClosureForCompute = (MTLDevice, MTLLibrary)->(MTLComputePipelineState)

/// The component for dispatching compute kernels.
public struct Compute: MetalBuilderComponent{
    
    var kernel: String{
        argumentsContainer.shaderName
    }
    
    var drawableTextureIndex: Int?
    var gridFit: GridFit?
    var indexType: IndexType = .ushort
    var threadsPerThreadgroup: MetalBinding<MTLSize>?
    
    var argumentsContainer: ArgumentsContainer
    
    var librarySource: String = ""
    var bodySource: String = ""
    
    var additionalEncodeClosure: MetalBinding<AdditionalEncodeClosureForCompute>?
    var additionalPiplineSetupClosure: MetalBinding<AdditionalPiplineSetupClosureForCompute>?
    var piplineSetupClosure: MetalBinding<PiplineSetupClosureForCompute>?
    
    public init(_ kernel: String, source: String = ""){
        self.argumentsContainer = ArgumentsContainer(shaderName: kernel)
    }
    
    mutating func setup(supportFamily4: Bool) throws -> ([BufferProtocol], [MTLTextureContainer]){
        try addArgumentBufferStructDecl()
        try setupGrid()
        try addComputeKernelArguments(addGridCheck: !supportFamily4)
        return self.argumentsContainer.getBuffersAndTextures()
    }
    mutating func addArgumentBufferStructDecl() throws{
        let argDecl = try argumentsContainer.setup()
        librarySource = argDecl + librarySource
    }
    mutating func addComputeKernelArguments(addGridCheck: Bool) throws{
        guard bodySource != ""
        else { return }
            
        var gridCheck = ""
        if addGridCheck{
            gridCheck = try gridFit!.gridCheck
        }
        
        let arg = try gridFit!
            .computeKernelArguments(bodyCode: bodySource,
                                    indexType: indexType, 
                                    gidCountBufferIndex: argumentsContainer.buffersAndBytesContainer.indexCounter)
        let kernelDecl = "void kernel \(argumentsContainer.shaderName) (\(arg)){"
        librarySource = librarySource + kernelDecl + gridCheck + bodySource + "}"
    }
    mutating func setupGrid() throws{
        if gridFit == nil{
            throw MetalBuilderComputeError
            .noGridFit("No information for threads dispatching was set for the kernel: " +
                       argumentsContainer.shaderName +
                       "\nUse 'grid' modifier or set index for drawable!")
        }
    }
}

// chaining functions for result builder
public extension Compute{
    /// Passes a buffer to the compute kernel.
    /// - Parameters:
    ///   - container: The buffer container.
    ///   - offset: The number of buffer elements to offset.
    ///   - index: Buffer index in kernel arguments.
    /// - Returns: The Compute component with the added buffer argument.
    ///
    /// This method adds a buffer to the compute function and doesn't change the Metal library code.
    /// Use it if you want to declare the kernel's argument manually.
    func buffer<T>(_ container: MTLBufferContainer<T>,
                   offset: MetalBinding<Int> = .constant(0), index: Int)->Compute{
        var c = self
        c.argumentsContainer.buffer(container, offset: offset, index: index)
        return c
    }
    /// Passes a buffer to the compute kernel.
    /// - Parameters:
    ///   - container: The buffer container.
    ///   - offset: The number of buffer elements to offset.
    ///   - argument: The buffer argument describing the declaration that should be added to the kernel.
    ///   - fitThreads: Indicates if the threads dispatched for the compute kernel should be calculated
    /// from the size of this buffer.
    /// - Returns: The Compute component with the added buffer argument.
    ///
    /// This method adds a buffer to the compute function and parses the Metal library code,
    /// automatically adding an argument declaration to the kernel function.
    /// Use this modifier if you do not want to declare the kernel's argument manually.
    func buffer<T>(_ container: MTLBufferContainer<T>, 
                   offset: MetalBinding<Int> = .constant(0),
                   argument: MetalBufferArgument,
                   fitThreads: Bool=false,
                   gridScale: MBGridScale?=nil,
                   separate: Bool = defaultBuffersSeparatePlacement)->Compute{
        var c = self
        c.argumentsContainer.buffer(container, offset: offset, argument: argument, separate: separate)
        if fitThreads || gridScale != nil{
            c.gridFit = .buffer(container, argument.name, gridScale ?? (1,1,1))
        }
        return c
    }
    /// Passes a buffer to the compute kernel.
    /// - Parameters:
    ///   - container: The buffer container.
    ///   - offset: The number of buffer elements to offset.
    ///   - space: The address space for this buffer, default is "constant".
    ///   - type: The optional Metal type of the elements of this buffer.If nil, the buffer's own `type` will be used.
    ///   - name: The optional name of the property that will be passed to the shader to access this buffer.
    ///   If nil, the buffer's own `name` will be used.
    ///   - fitThreads: Indicates if the threads dispatched for the compute kernel should be calculated
    /// from the size of this buffer.
    /// - Returns: The Compute component with the added buffer argument.
    ///
    /// This method adds a buffer to the compute function and parses the Metal library code,
    /// automatically adding an argument declaration to the kernel function.
    /// Use this modifier if you do not want to declare the kernel's argument manually.
    func buffer<T>(_ container: MTLBufferContainer<T>, offset: MetalBinding<Int> = .constant(0),
                   space: String="constant", type: String?=nil, name: String?=nil, fitThreads: Bool=false,
                   separate: Bool = defaultBuffersSeparatePlacement) -> Compute{
        
        let argument = try! MetalBufferArgument(container, space: space, type: type, name: name)
        return self.buffer(container, offset: offset, argument: argument, fitThreads: fitThreads,
                           separate: separate)
    }
    func bytes<T>(_ binding: Binding<T>, index: Int)->Compute{
        var c = self
        c.argumentsContainer.bytes(binding, index: index)
        return c
    }
    func bytes<T>(_ binding: Binding<T>, argument: MetalBytesArgument,
                  separate: Bool = defaultBytesSeparatePlacement)->Compute{
        var c = self
        c.argumentsContainer.bytes(binding, argument: argument, separate: separate)
        return c
    }
    func bytes<T>(_ binding: MetalBinding<T>, argument: MetalBytesArgument,
                  separate: Bool = defaultBytesSeparatePlacement)->Compute{
        var c = self
        c.argumentsContainer.bytes(binding.binding, argument: argument, separate: separate)
        return c
    }
    /// Passes a value to the compute kernel of a Compute component.
    /// - Parameters:
    ///   - binding: MetalBinding value created with the`@MetalState` property wrapper.
    ///   - space: The address space for this value, default is "constant".
    ///   - type: The optional Metal type of the value.
    ///   If nil, the value's own `type` will be used that is defined in `@MetalState` declaration for this value.
    ///   - name: The optional name of the property that will be passed to the shader to access this buffer.
    ///   If nil, the value's own `name` will be used that is defined in `@MetalState` declaration for this value.
    /// - Returns: The Render component with the added buffer argument to the compute kernel.
    ///
    /// This method adds a value to the  compute kernel of a Compute component and parses the Metal library code,
    /// automatically adding an argument declaration to the  compute kernel.
    /// Use this modifier if you do not want to declare the function's argument manually.
    func bytes<T>(_ binding: MetalBinding<T>, space: String = "constant", type: String?=nil,
                  name: String?=nil, index: Int?=nil,
                  separate: Bool = defaultBytesSeparatePlacement)->Compute{
        let argument = MetalBytesArgument(binding: binding, space: space, type: type, name: name, index: index)
        return bytes(binding, argument: argument)
    }
    /// Passes a value to the compute kernel of a Compute component.
    /// - Parameters:
    ///   - binding: The SwiftUI's binding.
    ///   - space: The address space for this value, default is "constant".
    ///   - type: The optional Metal type of the value.
    ///   If nil, the value's own `type` will be used that is defined in `@State` declaration for this value.
    ///   - name: The optional name of the property that will be passed to the shader to access this value.
    ///   If nil, the value's own `name` will be used that is defined in `@State` declaration for this value.
    /// - Returns: The Compute component with the added buffer argument to the compute kernel.
    ///
    /// This method adds a value to the compute kernel of a Compute component and parses the Metal library code,
    /// automatically adding an argument declaration to the compute kernel.
    /// Use this modifier if you do not want to declare the function's argument manually.
    func bytes<T>(_ binding: Binding<T>, space: String = "constant", 
                  type: String?=nil, name: String, index: Int?=nil,
                  separate: Bool = defaultBytesSeparatePlacement)->Compute{
        let metalBinding = MetalBinding(binding: binding, metalType: type, metalName: name)
        let argument = MetalBytesArgument(binding: metalBinding, space: space, type: type, name: name, index: index)
        return bytes(binding, argument: argument)
    }
    func uniforms(_ uniforms: UniformsContainer, name: String?=nil) -> Compute{
        var c = self
        c.argumentsContainer.uniforms(uniforms, name: name)
        return c
    }
    /// Passes a texture to the compute kernel.
    /// - Parameters:
    ///   - container: The texture container.
    ///   - index: The texture index in the kernel arguments.
    /// - Returns: The Compute component with the added texture argument.
    ///
    /// This method adds a texture to the compute function and doesn't change Metal library code.
    /// Use it if you want to declare the kernel's argument manually.
    func texture(_ container: MTLTextureContainer, index: Int)->Compute{
        var c = self
        c.argumentsContainer.texture(container, index: index)
        return c
    }
    /// Passes a texture to the compute kernel.
    /// - Parameters:
    ///   - container: The texture container or nil to use drawable texture.
    ///   - argument: The texture argument describing the declaration that should be added to the kernel.
    ///   - fitThreads: Indicates if the threads dispatched for the compute kernel should be calculated
    /// from the size of this texture.
    /// - Returns: The Compute component with the added texture argument.
    ///
    /// This method adds a texture to the compute function and parses the Metal library code,
    /// automatically adding an argument declaration to the kernel function.
    /// Use this modifier if you do not want to declare the kernel's argument manually.
    func texture(_ container: MTLTextureContainer?,
                 argument: MetalTextureArgument,
                 fitThreads: Bool=false,
                 gridScale: MBGridScale?=nil,
                 separate: Bool = defaultTexturesSeparatePlacement)->Compute{
        guard let container
        else{ return drawableTexture(argument: argument, fitThreads: fitThreads) }
        var c = self
        c.argumentsContainer.texture(container, argument: argument, separate: separate)
        if fitThreads || gridScale != nil{
            c.gridFit = .fitTexture(container, argument.name, gridScale ?? (1,1,1))
        }
        return c
    }
    /// Passes a drawable texture to the compute kernel.
    /// - Parameters:
    ///   - index: The texture index in the kernel arguments.
    /// - Returns: The Compute component with the added drawable texture argument.
    ///
    /// This method adds a drawable texture to the compute function and doesn't change Metal library code.
    /// Use it if you want to declare the kernel's argument manually.
//    func drawableTexture(index: Int, gridScale: MBGridScale?=nil)->Compute{
//        var c = self
//        c.drawableTextureIndex = index
//        c.gridFit = .drawable(gridScale ?? (1,1,1))
//        return c
//    }
    /// Passes a drawable texture to the compute kernel.
    /// - Parameters:
    ///   - argument: The texture argument describing the declaration that should be added to the kernel.
    ///   - fitThreads: Indicates whether the threads for the kernel should be dispatched to fit the drawable texture.
    ///
    /// This method adds a drawable texture to the compute function and parses the Metal library code,
    /// automatically adding an argument declaration to the kernel function.
    /// Use this modifier if you do not want to declare the kernel's argument manually.
    func drawableTexture(argument: MetalTextureArgument,
                         fitThreads: Bool = true,
                         gridScale: MBGridScale?=nil)->Compute{
        var c = self
        c.drawableTextureIndex = c.argumentsContainer.drawable(argument: argument)
        if fitThreads || gridScale != nil{
            c.gridFit = .drawable(argument.name, gridScale ?? (1,1,1))
        }
        return c
    }
    func grid(size: MetalBinding<Int>)->Compute{
        var c = self
        c.gridFit = .size1D(size)
        return c
    }
    func grid(size: Int)->Compute{
        var c = self
        c.gridFit = .size1D(MetalBinding<Int>.constant(size))
        return c
    }
    func grid(size2D: MetalBinding<(Int, Int)>)->Compute{
        var c = self
        c.gridFit = .size2D(size2D)
        return c
    }
    func grid(size3D: MetalBinding<MTLSize>)->Compute{
        var c = self
        c.gridFit = .size3D(size3D)
        return c
    }
//    func grid(fitTexture: MTLTextureContainer, gridScale: MBGridScale?=nil)->Compute{
//        var c = self
//        c.gridFit = .fitTexture(fitTexture, gridScale ?? (1,1,1))
//        return c
//    }
//    func gridFitDrawable(gridScale: MBGridScale?=nil)->Compute{
//        var c = self
//        c.gridFit = .drawable(gridScale ?? (1,1,1))
//        return c
//    }
//    func threadsFromBuffer(_ index: Int)->Compute{
//        var c = self
//        c.gridFit = .buffer(index)
//        return c
//    }
    func body(_ metalCode: String)->Compute{
        var c = self
        c.bodySource = metalCode
        return c
    }
    func source(_ metalCode: String)->Compute{
        var c = self
        c.librarySource = metalCode
        return c
    }
    /// Modifier for setting a closure for pipeline setup for Compute component.
    /// - Parameter closureBinding: MetalBinding to a closure for pipeline setup logic.
    /// - Returns: Compute component with a custom pipeline setup logic.
    ///
    /// Use this modifier if you want to create MTLComputePipelineState manually.
    func pipelineSetup(_ closureBinding: MetalBinding<PiplineSetupClosureForCompute>)->Compute{
        var c = self
        c.piplineSetupClosure = closureBinding
        return c
    }
    /// Modifier for setting a closure for pipeline setup for Compute component.
    /// - Parameter closure: closure for pipeline setup logic.
    /// - Returns: Compute component with a custom pipeline setup logic.
    ///
    /// Use this modifier if you want to create MTLComputePipelineState manually.
    func pipelineSetup(_ closure: @escaping PiplineSetupClosureForCompute)->Compute{
        self.pipelineSetup( MetalBinding<PiplineSetupClosureForCompute>.constant(closure))
    }
    /// Modifier for setting a closure for additional pipeline setup for Compute component.
    /// - Parameter closureBinding: MetalBinding to a closure for additional pipeline setup logic.
    /// - Returns: Compute component with the added additional pipeline setup logic.
    ///
    /// The closure provided in this modifier will run after all the internal pipeline setup logic is performed.
    func additionalPipelineSetup(_ closureBinding: MetalBinding<AdditionalPiplineSetupClosureForCompute>)->Compute{
        var c = self
        c.additionalPiplineSetupClosure = closureBinding
        return c
    }
    /// Modifier for setting a closure for additional pipeline setup for Compute component.
    /// - Parameter closure: closure for additional pipeline setup logic.
    /// - Returns: Compute component with the added additional pipeline setup logic.
    ///
    /// The closure provided in this modifier will run after all the internal pipeline setup logic is performed.
    func additionalPipelineSetup(_ closure: @escaping AdditionalPiplineSetupClosureForCompute)->Compute{
        self.additionalPipelineSetup( MetalBinding<AdditionalPiplineSetupClosureForCompute>.constant(closure))
    }
    /// Modifier for setting additional encode closure for Compute component.
    /// - Parameter closureBinding: MetalBinding to a closure for additional encode logic.
    /// - Returns: Compute component with the added additional encode logic.
    ///
    /// The closure provided in this modifier will run after all the internal encoding is performed
    /// right before the dispatch or before encoding of the next component.
    func additionalEncode(_ closureBinding: MetalBinding<AdditionalEncodeClosureForCompute>)->Compute{
        var c = self
        c.additionalEncodeClosure = closureBinding
        return c
    }
    /// Modifier for setting additional encode closure for Compute component.
    /// - Parameter closure: Closure for additional encode logic.
    /// - Returns: Compute component with the added additional encode logic.
    ///
    /// The closure provided in this modifier will run after all the internal encoding is performed
    /// right before the dispatch or before encoding of the next component.
    func additionalEncode(_ closure: @escaping AdditionalEncodeClosureForCompute)->Compute{
        self.additionalEncode(MetalBinding<AdditionalEncodeClosureForCompute>.constant(closure))
    }
    func threadsPerThreadgroup(_ sizeBinding: MetalBinding<MTLSize>)->Compute{
        var c = self
        c.threadsPerThreadgroup = sizeBinding
        return c
    }
    func threadsPerThreadgroup(_ size: MTLSize)->Compute{
        self.threadsPerThreadgroup(MetalBinding<MTLSize>.constant(size))
    }
    func gidIndexType(_ type: IndexType) -> Compute{
        var c = self
        c.indexType = indexType
        return c
    }
}
