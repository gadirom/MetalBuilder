//
//  MetalStructView.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 22.3.25..
//

import SwiftUI
import MetalKit

typealias EditableFieldInfo = (style: FieldStyle,
                               title: String,
                               count: Int,
                               integer: Bool)

public class MetalStructViewFonts: ObservableObject{
    public init(titleFont: Font = .title2, subtitleFont: Font = .title2, valueFont: Font = .title2.monospacedDigit()) {
        self.titleFont = titleFont
        self.subtitleFont = subtitleFont
        self.valueFont = valueFont
    }
    public init(){}
    
    @Published var titleFont: Font = .title2
    @Published var subtitleFont: Font = .title2
    @Published var valueFont: Font = .title2.monospacedDigit()
}

public struct MetalStructView<T: MetalStruct>: View {
    public init(_ state: StoredMetalState<T>, title: String?=nil,
                convertToColorSpace: Color.RGBColorSpace = .displayP3,
                onChange: (()->())?=nil){
        //self._state = ObservedObject(initialValue: state)
        self.state = state
        self.title = title
        self.state.onChange = onChange
        self.convertToColorSpace = convertToColorSpace
    }
    
    let title: String?
    let state: StoredMetalState<T>
    
    let convertToColorSpace: Color.RGBColorSpace
    
    public var content: some View{
        ForEach(state.state.dict.elements, id: \.key){ (key, arg) in
            
            let info: EditableFieldInfo = arg
            let binding = state.valueBinding(key)
            FieldView(binding: binding, info: info, convertToColorSpace: convertToColorSpace)
                //.padding([.top, .bottom])
        }
    }
    
    public var body: some View {
        VStack{
            Divider()
            if let title{
                CollapsableTitle(title: title){
                    content
                }
            }else{
                content
            }
        }
    }
}

struct FieldView: View{
    
    let binding: ValueBinding
    let info: EditableFieldInfo
    
    let convertToColorSpace: Color.RGBColorSpace
    
    var body: some View {
        switch info.style {
        case .value(let valueStyle):
            ValueEditorView(binding: binding,
                            style: valueStyle,
                            count: info.count,
                            title: info.title)
        case .color:
            ColorPickerView(binding: binding, count: info.count, title: info.title,
                            convertToColorSpace: convertToColorSpace)
        case .choice(let array, let style):
            ChoiceView(binding: binding, choices: array,
                       style: style, count: info.count, title: info.title)
        case .toggle(let toggleStyle):
            ToggleView(binding: binding, style: toggleStyle,
                       count: info.count, title: info.title)
        }
    }
}






//// Example usage
//let vector3f = SIMD3<Float>(1.0, 2.0, 3.0)
//extractSIMDInfo(from: vector3f)  // Output: This is a SIMD3<Float>
//
//let vector2f16 = SIMD2<Float16>(1.0, 2.0)
//extractSIMDInfo(from: vector2f16)  // Output: This is a SIMD2<Float16>

