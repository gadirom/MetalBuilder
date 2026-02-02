//
//  UniformFields.swift
//  EDR Test
//
//  Created by Roman Gaditskiy on 20.3.25..
//

import MetalKit
import OrderedCollections

public protocol UniformFields: RawRepresentable where RawValue == Int{
    var index: Int { get }
    var name: String { get }
}
public extension UniformFields{
    var index: Int {
        self.rawValue
    }
    var name: String{
        String(describing: self)
    }
}

public enum ValueStyle{
    case slider(ClosedRange<Double>)                // range of the slider
    case picker([Double], ChoiceStyle = .inline)    // picker variants, style
    case stepper(Double, ClosedRange<Double>)       // step size and range
    case manual(ClosedRange<Double>)                // enter manually, clamping to range
}

public enum ToggleStyle{
    case button                      // toggle as button
    case picker([String])            // picker variants
    case `switch`                     // switch toggle
}

public enum FieldStyle{
    case value(ValueStyle)
    case color
    case choice(OrderedDictionary<String, UInt8>, ChoiceStyle)
    case toggle(ToggleStyle)
    //case hide - use no style attribute to hide from UI
}

public enum ChoiceStyle{
    case segmented
    case inline
}

