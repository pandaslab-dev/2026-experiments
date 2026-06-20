//
//  LabelView.swift
//  LabelMaker
//
//  Created by Andy Mills on 1/26/25.
//

import SwiftUI

struct LabelView: View {
    @Environment(\.isEnabled) private var isEnabled
    @Binding var label: Label
    
    var body: some View {
        TextField("Type to enter text", text: $label.text, axis: .vertical)
            .frame(width: 500, height: isEnabled ? 500 : nil)
            .padding(50)
            .background(label.selectedColor(), in: RoundedRectangle(cornerRadius: label.cornerRadius))
            .foregroundStyle(.black)
            .font(.system(size: 40, weight: .semibold))
            .multilineTextAlignment(.center)
    }
}

#Preview {
    @Previewable @State var label = Label(text: "label text")
    LabelView(label: $label)
        .disabled(true)
}
