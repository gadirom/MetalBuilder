//
//  Toggles.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 23.3.25..
//

import SwiftUI
import MetalKit

struct ToggleView: View{
    
    let binding: ValueBinding
    let style: ToggleStyle
    let count: Int
    let title: String
    
    var body: some View {
        VStack{
            //TitleView(text: title)
            switch style {
            case .button:
                ButtonTogglesView(binding: binding, count: count, title: title)
            case .picker(let array):
                EmptyView()
            case .switch:
                SwitchTogglesView(binding: binding, count: count, title: title)
            }
        }
    }
}

struct ButtonTogglesView: View{
    
    let binding: ValueBinding
    let count: Int
    let title: String
    
    var body: some View {
        VStack{
            if count == 1{
                ButtonToggleView(binding: binding, index: 0, title: title)
            }else{
                HStack{
                    SubtitleView(text: title)
                    let components = ["x", "y", "z", "w"]
                    ForEach(0..<count){ i in
                        ButtonToggleView(binding: binding, index: i,
                                         title: components[i])
                    }
                }
            }
        }
    }
}

struct ButtonToggleView: View{
    
    let binding: ValueBinding
    let index: Int
    let title: String
    
    @State var value: Bool = false
    
    var body: some View {
        Toggle(isOn: $value) {
            SubtitleView(text: title)
        }.toggleStyle(.button)
            .onChange(of: value, initial: false){
                binding.set(index, value ? 1 : 0)
            }
            .onAppear{
                value = Int(binding.get(index)) == 1 
            }
    }
}

struct SwitchTogglesView: View{
    
    let binding: ValueBinding
    let count: Int
    let title: String
    
    var body: some View {
        VStack{
            if count == 1{
                SwitchToggleView(binding: binding, index: 0, title: title)
            }else{
                VStack{
                    SubtitleView(text: title)
                    let components = ["x", "y", "z", "w"]
                    ForEach(0..<count){ i in
                        SwitchToggleView(binding: binding, index: i,
                                         title: components[i])
                    }
                }
            }
        }
    }
}

struct SwitchToggleView: View{
    
    let binding: ValueBinding
    let index: Int
    let title: String
    
    @State var value: Bool = false
    
    var body: some View {
        Toggle(isOn: $value) {
            SubtitleView(text: title)
        }.toggleStyle(.switch)
            .onChange(of: value, initial: false){
                binding.set(index, value ? 1 : 0)
            }
            .onAppear{
                value = Int(binding.get(index)) == 1
            }
    }
}
