import SwiftUI

/// DispatchGroup Component
///
/// initializes a group of components
/// 'repeating' indicates number of subsequent dispatches for the group
/// the group can have it's own Metal library source code
public struct EncodeGroup: MetalBuilderComponent{
    
    var repeating: Binding<Int>
    public let librarySource: String?
    @MetalResultBuilder public let metalContent: MetalContent
    
    public init(repeating: Int = 1,
                librarySource: String? = nil,
                @MetalResultBuilder metalContent: ()->MetalContent) {
        self.librarySource = librarySource
        self.metalContent = metalContent()
        self.repeating = Binding<Int>.constant(repeating)
    }
    
    public init(repeating: Binding<Int>,
                librarySource: String? = nil,
                @MetalResultBuilder metalContent: ()->MetalContent) {
        self.librarySource = librarySource
        self.metalContent = metalContent()
        self.repeating = repeating
    }
}

// chaining functions
public extension EncodeGroup{
    func repeating(_ n: Binding<Int>)->EncodeGroup{
        var d = self
        d.repeating = n
        return d
    }
    func repeating(_ n: Int)->EncodeGroup{
        var d = self
        d.repeating = Binding<Int>.constant(n)
        return d
    }
}
