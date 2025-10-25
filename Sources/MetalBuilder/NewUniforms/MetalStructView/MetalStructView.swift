//
//  MetalStructView.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 22.3.25..
//

import SwiftUI
import MetalKit
import OrderedCollections

@Observable
public class MetalStructViewFonts{
    public init(titleFont: Font = .title2,
                subtitleFont: Font = .title2,
                valueFont: Font = .title2.monospacedDigit()) {
        self.titleFont = titleFont
        self.subtitleFont = subtitleFont
        self.valueFont = valueFont
    }
    public init(){}
    
    var titleFont: Font = .title2
    var subtitleFont: Font = .title2
    var valueFont: Font = .title2.monospacedDigit()
}

public struct MetalStructView<T: MetalStruct>: View {
    public init(_ state: StoredMetalState<T>,
                title: String?=nil,
                collapsable: Bool = true,
                convertToColorSpace: Color.RGBColorSpace = .displayP3,
                onChange: ((Bool)->())?=nil){// whether the change is from UI
        //self._state = ObservedObject(initialValue: state)
        self.state = state
        self.title = title
        self.collapsable = collapsable
        //self.onChange = onChange
        self.convertToColorSpace = convertToColorSpace
        
        state.initForView(onChangeForUI: onChange)
        //self.onChange = onChange
        //self.helpers = state.getBindings(onChange: onChange ?? {_ in })
        
    }
    
    let title: String?
    let state: StoredMetalState<T>
    
    let convertToColorSpace: Color.RGBColorSpace
    
    let collapsable: Bool
    
    //@StateObject var updater = ViewUpdater()
    
    //var onChange: ((Bool)->())?
    
    //@State var initialized = false
    
//    func initialize(){
//        //if !initialized{
////            print("init: \(title)")
//            state.generateHelpers(onChange: onChange ?? {_ in })
//            
//            state.onChange = { changedKeys in
//                _=changedKeys.map{ key in
//                    state.helpers[key]!.1.map{ helper in
//                        helper.updateFromNonUI()
//                    }
//                }
//                onChange?(false)
//            }
////        }else{
////            print("tried to init twice: \(title)")
////        }
//        //initialized = true
//    }
    
    //let helpers: OrderedDictionary<String, (EditableFieldInfo, [ObservableHelper])>
    
    //@State var wasInteraction = false
    
    //@State var interaction = false
    
//    func onStateChangeWithInteraction(){
//        onChange?(true)
//        //wasInteraction = false
//    }
//    func onStateChangeWithoutInteraction(){
//        onChange?(false)
//        //wasInteraction = false
//    }
    
    public var content: some View{
        Group{
            //        ForEach(Array(state.state.dict.elements.enumerated()), id: \.element.key){ a in
            //if initialized{
                ForEach(state.helpers.elements, id: \.key){ a in
                    
                    FieldView(info: a.value.0, values: a.value.1, convertToColorSpace: convertToColorSpace)
                    //.environment(updater)
                    // .id(updater.id(i))
                    //.padding([.top, .bottom])
                }
            //}
        }
    }
    
    public var body: some View {
        VStack{
            //Divider()
            if let title{
                if collapsable{
                    CollapsableTitle(title: title){
                        content
                    }
                }else{
                    TitleView(text: title)
                    content
                }
            }else{
                content
            }
        }
        .onAppear{
            //self.initialize()
//            self.state.forceUpdateView = self.updater.forceUpdateView
//            self.updater.onChange = self.onChange
        }
//        .onChange(of: interaction){
//            //if wasInteraction{
//                onStateChange()
//            //}
//        }
    }
}

struct FieldView: View{
    
//    @Environment(ViewUpdater.self) var updater
    
    let info: EditableFieldInfo
    let values: [ObservableValue]
    
    let convertToColorSpace: Color.RGBColorSpace
    
    //@Binding var updateToggle: Bool
    
    var body: some View {
        //Group{
            switch info.style {
            case .value(let valueStyle):
                ValueEditorView(values: values,
                                style: valueStyle,
                                count: info.count,
                                title: info.title)
            
            case .color:
                ColorPickerView(values: values, count: info.count, title: info.title,
                                convertToColorSpace: convertToColorSpace)
            case .choice(let dict, let style):
                ChoiceView(values: values, choices: dict,
                           style: style, count: info.count, title: info.title)
            case .toggle(let toggleStyle):
                ToggleView(values: values, style: toggleStyle,
                           count: info.count, title: info.title)
            }
        //}
//        .onChange(of: updater.toggle){
//            print("change!!")
//        }
    }
}






//// Example usage
//let vector3f = SIMD3<Float>(1.0, 2.0, 3.0)
//extractSIMDInfo(from: vector3f)  // Output: This is a SIMD3<Float>
//
//let vector2f16 = SIMD2<Float16>(1.0, 2.0)
//extractSIMDInfo(from: vector2f16)  // Output: This is a SIMD2<Float16>

