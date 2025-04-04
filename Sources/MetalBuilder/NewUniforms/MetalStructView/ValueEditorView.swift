//
//  ValueView.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 23.3.25..
//

import SwiftUI
import MetalKit

struct ValueEditorView: View{
    
    let binding: ValueBinding
    let style: ValueStyle
    let count: Int
    let title: String
    
    var body: some View {
        VStack{
            //TitleView(text: title)
            switch style {
            case .slider(let range):
                SlidersView(binding: binding, range: range, count: count, title: title)
            case .picker(let values):
                ValuePickersView(binding: binding, values: values, count: count, title: title)
            case .stepper(let stepSize, let range):
                SteppersView(binding: binding, stepSize: stepSize, range: range,
                             count: count, title: title)
            }
        }
    }
}

struct SlidersView: View{
    
    let binding: ValueBinding
    let range: ClosedRange<Double>
    let count: Int
    let title: String
    
    var body: some View {
            if count == 1{
                SliderView(binding: binding,
                           range: range,
                           index: 0,
                           title: title)
            }else{
                VStack{
                    SubtitleView(text: title)
                    let components = ["x", "y", "z", "w"]
                    ForEach(0..<count){ i in
                        HStack{
                            SliderView(binding: binding,
                                       range: range,
                                       index: i,
                                       title: components[i])
                        }
                }
            }
        }
    }
}

struct SliderView: View{
    
    let binding: ValueBinding
    let range: ClosedRange<Double>
    let index: Int
    let title: String
    
    @State var value: Double = 0
    
    var body: some View {
        VStack{
            HStack{
                SubtitleView(text: title)
                Spacer()
                ValueView(value: value, integer: binding.integer)
            }
            Slider(value: $value, in: range)
                .onChange(of: value, initial: false) {
                    binding.set(index, value)
                }
                .onAppear{
                    value = Double(binding.get(index))
                }
        }
    }
}

struct ValuePickersView: View{
    
    let binding: ValueBinding
    let values: [Double]
    let count: Int
    let title: String
    
    var body: some View {
        HStack{
            let components = ["x", "y", "z", "w"]
            if count == 1{
                HStack{
                    SubtitleView(text: title)
                    Spacer()
                    ValuePickerView(binding: binding,
                                    values: values,
                                    index: 0)
                }
            }else{
                ForEach(0..<count){ i in
                    HStack{
                        SubtitleView(text: components[i]+":")
                        Spacer()
                        ValuePickerView(binding: binding,
                                        values: values,
                                        index: i)
                    }
                }
            }
        }
    }
}

struct ValuePickerView: View{
    
    let binding: ValueBinding
    let values: [Double]
    let index: Int
    
    @State var value: Float = 0
    
    var body: some View {
        Picker("", selection: $value){
            ForEach(values, id: \.self){ v in
                let fv = Float(v)
                ValueView(value: v, integer: binding.integer).tag(fv)
            }
        }
        .onChange(of: value, initial: false) {
                binding.set(index, value)
            }
            .onAppear{
                value = Float((binding.get(index) as! Double))
                print(value)
            }
    }
}

struct SteppersView: View{
    
    let binding: ValueBinding
    let stepSize: Double
    let range: ClosedRange<Double>
    let count: Int
    let title: String
    
    var body: some View {
        HStack{
            SubtitleView(text: title)
            Spacer()
            VStack{
                ForEach(0..<count){ i in
                    StepperView(binding: binding,
                                stepSize: stepSize,
                                range: range,
                                index: i)
                }
            }
        }
    }
}

struct StepperView: View{
    
    let binding: ValueBinding
    let stepSize: Double
    let range: ClosedRange<Double>
    let index: Int
    
    @State var value: Double = 0
    
    var body: some View {
        VStack{
            Stepper(label: {
                ValueView(value: value, integer: binding.integer)
            }, onIncrement: {
                value += stepSize
                if value>range.upperBound{ value = range.upperBound }
                binding.set(index, value)
            },
                    onDecrement: {
                value -= stepSize
                if value<range.lowerBound{ value = range.lowerBound }
                binding.set(index, value)
            })
            .onChange(of: value, initial: false) {
                    binding.set(index, value)
                }
            .onAppear{
                value = Double(binding.get(index))
            }
        }
    }
}
