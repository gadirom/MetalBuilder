//
//  Untitled.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 21.3.25..
//
import MetalKit
import OrderedCollections

public protocol EnumForPicker: CaseIterable, RawRepresentable where RawValue == UInt8{}
public extension EnumForPicker{
    static var all: [String]{
        Self.allCases.map{ String(describing: $0) }
    }
}

enum PickerVariants: UInt8, EnumForPicker{
    case first
    case second
}
/*
@Editable
struct X: MetalStruct{
    @Field(.value(.slider(0...1)))
    var x: Float = 0
    @Field(.color)
    var y: simd_half3 = [0,0,0]
    @Field(.value(.picker([0.5, 1.7, 3.2])))
    var z: simd_float2 = [0, 0]
    @Field(.value(.stepper(0.5)))
    var w: simd_float4 = [0, 0]
    @Field(.enumPicker(PickerVariants.all))
    var picker: simd_uchar1 = 0
}

let x = {
    var x = X()
    //x["x"] = 0.1
    
    print(x)
    
}()
*/
/*struct X: MetalStruct{
    @Field(.hide)
    var x: Float = 0
    @Field(.value(0...100), .picker)
    var y: simd_half2 = [0,0,0]
    @Field(.enumPicker(PickerVariants.allCases))
    var picker: UInt8 = 0
}*/

// Create an instance and access collected properties
//let person = Person()
//print(person._collectedProperties)


// Create an instance and access collected properties

//let person = Person()
//print(person._collectedProperties)


