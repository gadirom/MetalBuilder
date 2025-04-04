//
//  TitleView.swift
//  MetalBuilder
//
//  Created by Roman Gaditskiy on 23.3.25..
//

import SwiftUI

struct TitleView: View{
    
    @EnvironmentObject var fonts: MetalStructViewFonts
    
    let text: String
    
    var body: some View {
        Text(text)
            .font(fonts.titleFont)
            //.font(.title2)
    }
}

struct SubtitleView: View{
    
    @EnvironmentObject var fonts: MetalStructViewFonts
    
    let text: String
    
    var body: some View {
        //HStack{
        Text(text)
            .font(fonts.subtitleFont)
             //.font(.title3)
            //Spacer()
        //}
    }
}
