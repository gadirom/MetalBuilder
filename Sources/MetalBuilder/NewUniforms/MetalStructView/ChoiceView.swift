//
//  CjoiceView.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 24.3.25..
//

import SwiftUI

struct ChoiceView: View{
    
    let binding: ValueBinding
    let choices: [String]
    let style: ChoiceStyle
    let count: Int
    let title: String
    
    var body: some View {
        VStack{
            if count>1{
                EmptyView()
            }else{
                switch style {
                    case .segmented:
                    SegmentedPickerView(binding: binding, choices: choices, index: 0,
                                        title: title)
                    case .inline:
                        InlinePickerView(binding: binding, choices: choices, index: 0,
                                         title: title)
                }
            }
        }
    }
}

struct SegmentedPickerView: View{
    
    let binding: ValueBinding
    let choices: [String]
    let index: Int
    let title: String
    
    @State var value: Int = 0
    
    var body: some View {
        VStack{
            SubtitleView(text: title)
            Picker("", selection: $value){
                ForEach(Array(choices.enumerated()), id: \.element){ c in
                    SubtitleView(text:c.element)
                        .tag(c.offset)
                }
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: value, initial: false) {
                binding.set(index, Float(value))
            }
        .onAppear{
            value = Int((binding.get(index) as! Double))
        }
    }
}

struct InlinePickerView: View{
    
    let binding: ValueBinding
    let choices: [String]
    let index: Int
    let title: String
    
    @State var value: Int = 0
    
    var body: some View {
        HStack{
            SubtitleView(text: title)
            Spacer()
            Picker("", selection: $value){
                ForEach(Array(choices.enumerated()), id: \.element){ c in
                    SubtitleView(text: c.element)
                        .tag(c.offset)
                }
            }
        }
        .onChange(of: value, initial: false) {
                binding.set(index, Float(value))
        }
        .onAppear{
            value = Int((binding.get(index) as! Double))
        }
    }
}
