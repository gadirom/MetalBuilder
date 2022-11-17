import SwiftUI

public extension MetalBuilderView{
    func onResize(perform: @escaping (CGSize)->())->MetalBuilderView{
        var v = self
        v.viewSettings.onResizeCode = perform
        return v
//        MetalBuilderView(librarySource: librarySource,
//                         helpers: helpers,
//                         isDrawing: $isDrawing,
//                         metalContent: metalContent,
//                         onResizeCode: perform)
    }
}
