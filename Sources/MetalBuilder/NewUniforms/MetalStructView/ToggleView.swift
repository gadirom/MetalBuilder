//
//  Toggles.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 23.3.25..
//

import SwiftUI
import MetalKit

struct ToggleView: View{
    
    let values: [ObservableValue]
    let style: ToggleStyle
    let count: Int
    let title: String
    
    var body: some View {
        VStack{
            //TitleView(text: title)
            switch style {
            case .button:
                ButtonTogglesView(values: values, count: count, title: title)
            case .picker(let array):
                EmptyView()
            case .switch:
                SwitchTogglesView(values: values, count: count, title: title)
            }
        }
    }
}

struct ButtonTogglesView: View{
    
    let values: [ObservableValue]
    let count: Int
    let title: String
    
    var body: some View {
        VStack{
            if count == 1{
                ButtonToggleView(value: values.first!, title: title)
            }else{
                HStack{
                    SubtitleView(text: title)
                    let components = ["x", "y", "z", "w"]
                    ForEach(0..<count){ i in
                        ButtonToggleView(value: values[i],
                                         title: components[i])
                    }
                }
            }
        }
    }
}

struct ButtonToggleView: View{
    
    var value: ObservableValue
    let title: String
    
    var body: some View {
        Toggle(isOn: value.boolBinding) {
            SubtitleView(text: title)
        }.toggleStyle(.button)
    }
}

struct SwitchTogglesView: View{
    
    let values: [ObservableValue]
    let count: Int
    let title: String
    
    var body: some View {
        VStack{
            if count == 1{
                SwitchToggleView(value: values.first!, title: title)
            }else{
                VStack{
                    SubtitleView(text: title)
                    let components = ["x", "y", "z", "w"]
                    ForEach(0..<count){ i in
                        SwitchToggleView(value: values[i],
                                         title: components[i])
                    }
                }
            }
        }
    }
}

struct SwitchToggleView: View{
    
    var value: ObservableValue
    let title: String
    
    var body: some View {
        Toggle(isOn: value.boolBinding) {
            SubtitleView(text: title)
        }.toggleStyle(.switch)
    }
}
