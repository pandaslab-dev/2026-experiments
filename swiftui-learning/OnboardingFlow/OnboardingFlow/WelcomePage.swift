//
//  WelcomePage.swift
//  OnboardingFlow
//

//

import SwiftUI

struct WelcomePage: View {
    var body: some View {
        VStack{
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .frame(width: 150, height: 150)
                    .foregroundStyle(.tint)
                
                Image(systemName: "teddybear")
                    .font(.system(size: 70))
                    .foregroundStyle(.white)
            }
            Text("welcome to bear chat")
                .font(.title)
                .fontWeight(.semibold)
                //.border(.black, width: 1.5)
                .padding(.top)
            Text("ROOARRR GROARRGH ROARRRGHHH GRRRRRR GRROARR RROARRRGH ROARRR")
                .multilineTextAlignment(    .center)
                //.border(.green, width: 1.5)
                
        }
        //.border(.blue, width: 1.5)
        .padding()
        //.border(.red, width: 1.5)
    }
}

#Preview {
    WelcomePage()
}
