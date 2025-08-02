//
//  CjoiceView.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 24.3.25..
//

import SwiftUI
import OrderedCollections

struct ChoiceView: View{
    
    var values: [ObservableValue]
    let choices: EnumForPicker.Dict
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
                        SegmentedPickerView(value: values.first!, choices: choices, title: title)
                    case .inline:
                        InlinePickerView(value: values.first!, choices: choices, title: title)
                }
            }
        }
    }
}

struct SegmentedPickerView: View{
    
    let value: ObservableValue
    let choices: EnumForPicker.Dict
    let title: String
    
    var body: some View {
        VStack{
            SubtitleView(text: title)
            Picker("", selection: value.pickerBindning){
                ForEach(choices.keys, id: \.self){ key in
                    SubtitleView(text: key)
                        .tag(choices[key]!)
                }
            }
        }
        .pickerStyle(.segmented)
    }
}

struct InlinePickerView: View{
    
    var value: ObservableValue
    let choices: EnumForPicker.Dict
    let title: String
    
    var body: some View {
        HStack{
            SubtitleView(text: title)
            Spacer()
            Picker("", selection: value.pickerBindning){
                ForEach(choices.keys, id: \.self){ key in
                    SubtitleView(text: key)
                        .tag(choices[key]!)
                }
            }
        }
    }
}
