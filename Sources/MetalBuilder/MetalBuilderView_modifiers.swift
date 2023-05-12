import SwiftUI

public extension MetalBuilderView{
    /// Adds an action to perform when the view size is changed.
    /// - Parameter perform: The closure that takes the size of the view in pixels.
    /// - Returns: A MetalBuilderView that triggers the action on it's resize.
    ///
    /// The closure runs before the rendering starts and then every time the view changes it's size.
    /// Use it to make preparations before rendering or to make changes according to the changes of the view's size.
    func onResize(perform: @escaping (CGSize)->())->MetalBuilderView{
        var v = self
        v.onResizeCode = perform
        return v
    }
    func onSetup(perform: @escaping ()->())->MetalBuilderView{
        var v = self
        v.setupFunction = perform
        return v
    }
    func onStartup(perform: @escaping (MTLDevice)->())->MetalBuilderView{
        var v = self
        v.startupFunction = perform
        return v
    }
}
