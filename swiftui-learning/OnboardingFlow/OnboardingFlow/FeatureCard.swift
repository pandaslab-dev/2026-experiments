//
//  FeatureCard.swift
//  OnboardingFlow
//
//  Created by Andy Mills on 1/14/25.
//

import SwiftUI

struct FeatureCard: View {
    let iconName: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.largeTitle)
                .frame(width: 50)
                .padding(.trailing, 10)
            
            Text(description)
            
            Spacer()
        }
        .padding()
        .background{
            RoundedRectangle(cornerRadius: 12)
            .foregroundStyle(.tint)
            .opacity(0.25)
            .brightness(-0.4)
        }
        .foregroundStyle(.white)
    }
}

#Preview {
    FeatureCard(iconName: "ellipsis.message.fill", description: "GRRROAR ROARRRRGH ROARRR")
}
