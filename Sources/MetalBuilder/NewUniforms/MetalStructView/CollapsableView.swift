//
//  CollapsableView.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 23. 3. 2026..
//

import SwiftUI

public struct CollapsableView<T: View>: View {
    
    public init(title: String?, collapsable: Bool, @ViewBuilder content: @escaping ()->(T)) {
        self.title = title
        self.content = content
        self.collapsable = collapsable
    }
    
    let collapsable: Bool
    let title: String?
    @ViewBuilder var content: ()->(T)
    
    public var body: some View{
        VStack{
            if let title{
                if collapsable{
                    CollapsableTitle(title: title){
                        content()
                    }
                }else{
                    TitleView(text: title)
                    content()
                }
            }else{
                content()
            }
        }
    }
}
