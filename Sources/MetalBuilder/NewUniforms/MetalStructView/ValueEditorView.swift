//
//  ValueView.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 23.3.25..
//

import SwiftUI
import MetalKit

struct ValueEditorView: View{
    
    let values: [ObservableValue]
    let style: ValueStyle
    let count: Int
    let title: String
    
    var body: some View {
        VStack{
            //TitleView(text: title)
            switch style {
            case .slider(let range):
                SlidersView(values: values, range: range, count: count, title: title)
            case .picker(let choice):
                ValuePickersView(values: values, choice: choice, count: count, title: title)
            case .stepper(let stepSize, let range):
                SteppersView(values: values, stepSize: stepSize, range: range,
                             count: count, title: title)
            case .manual(let range):
                ManualValuesView(values: values, range: range, count: count, title: title)
            }
        }
    }
}

struct SlidersView: View{
    
    let values: [ObservableValue]
    let range: ClosedRange<Double>
    let count: Int
    let title: String
    
    var body: some View {
            if count == 1{
                SliderView(value: values.first!,
                           range: range,
                           title: title)
            }else{
                VStack{
                    SubtitleView(text: title)
                    ForEach(0..<count){ i in
                        HStack{
                            SliderView(value: values[i],
                                       range: range,
                                       title: componentTitle(i))
                        }
                }
            }
        }
    }
}

struct SliderView: View{
    
    var value: ObservableValue
    
    let range: ClosedRange<Double>
    let title: String
    
   // @State var wasNonUIUpdate = false
    
    var body: some View {
        VStack{
            HStack{
                SubtitleView(text: title)
                Spacer()
                ValueView(value: value.doubleBinding.wrappedValue, integer: value.isInteger)
            }
            Slider(value: value.doubleBinding, in: range)
//            .onAppear{
//                //helper.value = helper.getValue()
//            }
        }
    }
}

struct ValuePickersView: View{
    
    let values: [ObservableValue]
    let choice: [Double]
    let count: Int
    let title: String
    
    var body: some View {
        HStack{
            
            if count == 1{
                HStack{
                    SubtitleView(text: title)
                    Spacer()
                    ValuePickerView(value: values.first!,
                                    choice: choice)
                }
            }else{
                ForEach(0..<count){ i in
                    HStack{
                        SubtitleView(text: componentTitle(i))
                        Spacer()
                        ValuePickerView(value: values[i],
                                        choice: choice)
                    }
                }
            }
        }
    }
}

struct ValuePickerView: View{
    
    var value: ObservableValue
    let choice: [Double]
    
    var body: some View {
        Picker("", selection: value.doubleBinding){
            ForEach(choice, id: \.self){ v in
                let fv = Float(v)
                ValueView(value: v, integer: value.isInteger).tag(fv)
            }
        }
    }
}

struct SteppersView: View{
    
    let values: [ObservableValue]
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
                    StepperView(value: values[i],
                                stepSize: stepSize,
                                range: range)
                }
            }
        }
    }
}

struct StepperView: View{
    
    var value: ObservableValue
    let stepSize: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack{
            Stepper(label: {
                ValueView(value: value.doubleBinding.wrappedValue, integer: value.isInteger)
            }, onIncrement: {
                var newValue = value.doubleBinding.wrappedValue + stepSize
                if newValue>range.upperBound{ newValue = range.upperBound }
                value.doubleBinding.wrappedValue = newValue
            }, onDecrement: {
                var newValue = value.doubleBinding.wrappedValue - stepSize
                if newValue<range.lowerBound{ newValue = range.lowerBound }
                value.doubleBinding.wrappedValue = newValue
            })
        }
    }
}

struct ManualValuesView: View{
    
    let values: [ObservableValue]
    let range: ClosedRange<Double>
    let count: Int
    let title: String
    
    var body: some View {
        VStack{
            SubtitleView(text: title)
            //Spacer()
            VStack{
                ForEach(0..<count){ i in
                    //HStack{
//                        SubtitleView(text: componentTitle(i))
                        ManualValueView(value: values[i],
                                        range: range,
                                        title: componentTitle(i))
                    //}
                }
            }
        }
    }
}

struct ManualValueView: View{
    
    var value: ObservableValue
    let range: ClosedRange<Double>
    let title: String
    
    var body: some View {
        //VStack{
        DoubleInputView(value: value.doubleBinding, title: title, range: range)
            
        //}
    }
}

struct DoubleInputView: View {
    @Binding var value: Double
    let title: String
    
    // Optional parameters with default values
    var format: String = "%.2f"
    var keyboardType: UIKeyboardType = .decimalPad
    
    let range: ClosedRange<Double>
    
    @State private var textValue: String = ""
    
    init(value: Binding<Double>, title: String, format: String = "%.2f", keyboardType: UIKeyboardType = .decimalPad, range: ClosedRange<Double>) {
        self._value = value
        self.title = title
        self.format = format
        self.keyboardType = keyboardType
        self.range = range
        self._textValue = State(initialValue: String(format: format, value.wrappedValue))
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                //.padding(.bottom, 4)
            
            TextField("", text: $textValue)
                .keyboardType(keyboardType)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onSubmit { //newValue in
                    if let doubleValue = Double(textValue.replacingOccurrences(of: ",", with: ".")) {
                        value = min(max(doubleValue, range.lowerBound), range.upperBound)
                    }
                }
                .onChange(of: value) { newValue in
                    textValue = String(format: format, newValue)
                }
        }
        //.padding(.vertical, 8)
    }
}

func componentTitle(_ i: Int) -> String{
    let components = ["x", "y", "z", "w"]
    return components[i]+":"
}
