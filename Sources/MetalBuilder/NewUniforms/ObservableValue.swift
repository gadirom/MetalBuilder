//
//  ObservableValue.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 25. 5. 2025..
//


import MetalKit
import SwiftUI
import OrderedCollections

typealias ValueBinding = (get: (Int)->(any BinaryFloatingPoint),
                          set: (Int, any BinaryFloatingPoint)->(),
                          defaultValue: (Int)->(any BinaryFloatingPoint),
                          integer: Bool)

typealias SingleValueBinding = (get: ()->(any BinaryFloatingPoint),
                                set: (any BinaryFloatingPoint)->(),
                                defaultValue: ()->(any BinaryFloatingPoint),
                                integer: Bool)

@Observable
class ObservableValue{
    init(binding: SingleValueBinding,
         onChange: @escaping (Bool)->()){
        self.binding = binding
        self.onChange = onChange
        
        value = getValue()
    }
    
    private func setValueFromUI(_ value: Double){
        //self.value = value
        if isInteger{
            self.binding.set(value.rounded(.towardZero))
        }else{
            self.binding.set(value)
        }
        onChange(true)
    }
    
    private func getValue() -> Double{
        binding.get() as! Double
    }
    
    private let onChange: (Bool)->()
    
    private var value: Double = 0{
        didSet{
            print("value set: ", value)
        }
    }
    
    private func getter()->(Double){
        value
    }
    private func setter(_ v: Double)->(){
        //print("setter: ", v)
        self.value = v
        self.setValueFromUI(v)
    }
    
    private var defaultValue: Double{
        binding.defaultValue as! Double
    }
    
    //@Published var updater: Bool = false
    private let binding: SingleValueBinding
}

extension ObservableValue{
    func updateFromNonUI(){
        self.value = getValue()
        //updater.toggle()
    }
    
    var isInteger: Bool{
        binding.integer
    }
    
    var doubleBinding: Binding<Double>{
        .init(
            get: getter,
            set: setter
        )
    }
    
    var doubleDefault: Double{
        defaultValue
    }
    
    var pickerBindning: Binding<EnumForPickerRawValue>{
        .init(
            get: { EnumForPickerRawValue(self.getter()) },
            set: { self.setter(Double($0)) }
        )
    }
    
    var pickerDefault: EnumForPickerRawValue{
        EnumForPickerRawValue(defaultValue)
    }
    
    var boolBinding: Binding<Bool>{
        .init(
            get: {
                //print("bool getter: ", self.value)
                return self.getter()>0
            },
            set: {
                self.setter($0 ? 1 : 0)
                print("bool setter: ", self.value)
            }
        )
    }
    
    var boolDefault: Bool{
        defaultValue>0
    }
    
}
