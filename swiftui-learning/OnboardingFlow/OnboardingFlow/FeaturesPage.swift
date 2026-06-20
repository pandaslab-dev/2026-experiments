//
//  FeaturesPage.swift
//  OnboardingFlow
//
//  Created by Andy Mills on 1/14/25.
//

import SwiftUI

struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Features")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom)
                .padding(.top, 100)
            
            FeatureCard(iconName: "ellipsis.message.fill", description: "GRRROAR ROARRRRGH ROARRR")
            
            FeatureCard(iconName: "pawprint.fill", description: "GRRR ROARRGHH")
            
            FeatureCard(iconName: "fish.circle", description: "salmon from river")
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    FeaturesPage()
        .frame(maxHeight: .infinity)
        .background(Gradient(colors: gradientColors))
        .foregroundStyle(.white)
}
