//
//  SettingsStack.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 14. 12. 2025..
//

import SwiftUI

public struct StoredMetalStateItem {
    public init<T: MetalStruct>(state: StoredMetalState<T>,
                                collapsable: Bool,
                                show: Bool,
                                title: String?) {
        self.state = state as! any AnyStoredMetalState
        self.collapsable = collapsable
        self.show = show
        self.title = title
    }
    let state: AnyStoredMetalState
    public var collapsable: Bool
    public var show: Bool
    public var title: String?
    
}

@Observable
@MainActor
open class SettingsStack{
    public init(settings: [StoredMetalStateItem],
                title: String? = nil,
                collapsable: Bool = false) {
        self.settings = settings
        
        self.title = title
        self.collapsable = collapsable
    }
    
    public func setup(){
        for s in settings{
            s.state.onChangeForUISelf?(true)// true since logically it is from UI?
        }
    }
    
    let title: String?
    let collapsable: Bool
    
    public var settings: [StoredMetalStateItem] = []
    public var view: some View {
        CollapsableView(title: title, collapsable: collapsable) {
            ForEach(Array(self.settings.enumerated()), id: \.offset){ item in
                let s = item.element
                MetalStructView(s.state,
                                title: s.title,
                                collapsable: s.collapsable
                )
            }
        }
    }
}
