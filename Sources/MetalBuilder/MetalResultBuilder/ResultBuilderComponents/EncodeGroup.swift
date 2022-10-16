import SwiftUI

/// DispatchGroup Component
///
/// initializes a group of components
/// 'repeating' indicates number of subsequent dispatches for the group
public struct EncodeGroup: MetalBuilderComponent{
    
    var repeating: Binding<Int>
    var active: Binding<Bool>
    //public let librarySource: String?
    @MetalResultBuilder public let metalContent: MetalContent
    
    public init(repeating: MetalBinding<Int>,
                active: MetalBinding<Bool>,
                //librarySource: String? = nil,
                @MetalResultBuilder metalContent: ()->MetalContent) {
        self.init(repeating: repeating.binding,
                  active: active.binding,
                  //librarySource: librarySource,
                  metalContent: metalContent)
    }
    
    public init(repeating: Int = 1,
                active: MetalBinding<Bool>,
                //librarySource: String? = nil,
                @MetalResultBuilder metalContent: ()->MetalContent) {
        self.init(repeating: Binding<Int>.constant(repeating),
                  active: active.binding,
                  //librarySource: librarySource,
                  metalContent: metalContent)
    }
    
    public init(repeating: Int = 1,
                active: Binding<Bool> = Binding<Bool>.constant(true),
                //librarySource: String? = nil,
                @MetalResultBuilder metalContent: ()->MetalContent) {
        self.init(repeating: Binding<Int>.constant(repeating),
                  active: active,
                  //librarySource: librarySource,
                  metalContent: metalContent)
    }
    
    public init(repeating: Binding<Int>,
                active: Binding<Bool> = Binding<Bool>.constant(true),
                //librarySource: String? = nil,
                @MetalResultBuilder metalContent: ()->MetalContent) {
        //self.librarySource = librarySource
        self.metalContent = metalContent()
        self.repeating = repeating
        self.active = active
    }
}

// chaining functions
public extension EncodeGroup{
    func repeating(_ n: Binding<Int>)->EncodeGroup{
        var d = self
        d.repeating = n
        return d
    }
    func repeating(_ n: MetalBinding<Int>)->EncodeGroup{
        return repeating(n.binding)
    }
    func repeating(_ n: Int)->EncodeGroup{
        var d = self
        d.repeating = Binding<Int>.constant(n)
        return d
    }
}
