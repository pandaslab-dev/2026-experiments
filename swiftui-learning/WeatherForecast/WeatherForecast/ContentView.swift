//
//  ContentView.swift
//  WeatherForecast
//
//  Created by Andy Mills on 1/14/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("bear weather")
            .fontWeight(Font.Weight.bold)
            .font(Font.system(size: 36))
        VStack{
            HStack {
                DayForecast(day: "Mon", high: 48, low: 32, isRainy: false)
                
                DayForecast(day: "Tues", high: 53, low: 34, isRainy: false)
                
                DayForecast(day: "Wed", high: 50, low: 33, isRainy: false)
            }
            HStack {
                DayForecast(day: "Thurs", high: 58, low: 43, isRainy: false)
                
                DayForecast(day: "Fri", high: 57, low: 33, isRainy: true)
                
                DayForecast(day: "Sat", high: 35, low: 17, isRainy: true)
            }
        }
    }
}

#Preview {
    ContentView()
}

struct DayForecast: View {
    let day: String
    let high: Int
    let low: Int
    let isRainy: Bool
    
    var iconName: String {
        if isRainy {
            return "cloud.rain.fill"
        } else {
            return "sun.max.fill"
        }
        
    }
    
    var iconColor: Color {
        if isRainy {
            return Color.blue
        } else {
            return Color.yellow
        }
    }
    
    var body: some View {
        
        VStack {
            Text(day)
                .font(Font.headline)
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .font(Font.largeTitle)
                .padding(5)
            Text("High: \(high)º")
                .fontWeight(Font.Weight.semibold)
            Text("Low: \(low)º")
                .fontWeight(Font.Weight.medium)
                .foregroundStyle(Color.secondary)
        }
        .padding()
    }
}
