//
//  ColorButton.swift
//  LabelMaker
//
//  Created by Andy Mills on 1/26/25.
//

import SwiftUI

struct ColorButton: View {
    @State var color: Color
    var selectColor: () -> Void
    
    var body: some View {
        Button {
            selectColor()
        } label : {
            Circle()
                .foregroundStyle(color)
                .frame(height: 34)
        }
        .buttonBorderShape(.circle)
    }
}

#Preview {
    ColorButton(color: .cyan) {
        
}
}
