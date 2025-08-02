//
//  ValueView.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 23.3.25..
//

import SwiftUI

struct ValueView: View {
    
    @Environment(MetalStructViewFonts.self) var fonts
    
    let value: Double
    let integer: Bool
    
    var body: some View {
        if integer{
            Text(value.rounded(.towardZero), format: .number.rounded(increment: 1))
                .font(fonts.valueFont)
                .monospaced()
        }else{
            Text(value, format: .number.rounded(increment: 0.001))
                .font(fonts.valueFont)
                .monospaced()
        }
    }
}
