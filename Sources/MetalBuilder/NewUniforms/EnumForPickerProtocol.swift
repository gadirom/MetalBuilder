//
//  Untitled.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 21.3.25..
//
import MetalKit
import OrderedCollections

public typealias EnumForPickerRawValue = UInt8

public protocol EnumForPicker: CaseIterable, RawRepresentable where RawValue == EnumForPickerRawValue{
    typealias Dict = OrderedDictionary<String, EnumForPickerRawValue>
    var name: String{ get }
}
public extension EnumForPicker{
    var name: String{
        String(describing: self)
    }
    static var all: Dict{
        .init(uniqueKeysWithValues: Self.allCases.map{ ($0.name, $0.rawValue) })
    }
}
public extension EnumForPicker{
    func equals(to rawValueGetter: @escaping ()->(EnumForPickerRawValue))-> MetalBinding<Bool>{
        .init{
            rawValueGetter() == self.rawValue
        }
    }
    static func `switch`(_ rawValueGetter: @escaping ()->(EnumForPickerRawValue),
                         _ cases: (Self, MetalBuildingBlock)...) -> EncodeGroup{
        EncodeGroup(metalContent:
            cases.map { `case`, block in
                EncodeGroup(active: `case`.equals(to: rawValueGetter)){
                    block
                }
            }
        )
    }
    //compares binding.rawValue with source value
    //if they are equal returns false
    //if not - set binding to source and return true
    static func compareAndSet(_ binding: MetalBinding<Self>,
                       _ rawValueGetter: @escaping ()->(EnumForPickerRawValue)) -> MetalBinding<Bool>{
        .init(get: {
            let sourceValue = rawValueGetter()
            if binding.wrappedValue.rawValue == sourceValue{
                return false
            }else{
                binding.wrappedValue = Self(rawValue: sourceValue)!
                return true
            }
        })
    }
}

public extension MetalBinding where T: EnumForPicker{
    static func ===(lhs: MetalBinding<T>, rhs: @escaping ()->(EnumForPickerRawValue)) -> MetalBinding<Bool>{
        T.compareAndSet(lhs, rhs)
    }
}

public extension EnumForPicker{
    static func metalSwitch(_ value: String, _ cases: (Self, String)...) -> String{
        """
        switch(\(value)){
            \(cases.map{ caseValue, code in
            """
            case \(caseValue.rawValue): \(code)
            break;
            """
        }.joined(separator: "\n"))
        }
        """
    }
}
//
//enum PickerVariants: UInt8, EnumForPicker{
//    case first
//    case second
//}
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


