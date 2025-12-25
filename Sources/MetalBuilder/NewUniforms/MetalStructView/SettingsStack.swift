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
    public init(settings: [StoredMetalStateItem]) {
        self.settings = settings
//        for s in settings{
//            s.state.
//        }
    }
    public var settings: [StoredMetalStateItem] = []
    public var view: some View{
        ForEach(Array(settings.enumerated()), id: \.offset){ item in
            let s = item.element
            MetalStructView(s.state,
                            title: s.title,
                            collapsable: s.collapsable
            )
        }
    }
}
