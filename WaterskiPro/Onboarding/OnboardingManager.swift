//
//  OnboardingManager.swift
//  Waterski Pro
//
//  Created by Kaden Thompson on 4/26/24.
//

import Foundation

struct OnboardingItem: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let content: String
}

extension OnboardingItem: Equatable {}

final class OnboardingManager: ObservableObject {
    @Published private(set) var items: [OnboardingItem] = []

    func load() {
        items = [
            .init(emoji: "🌊",
                  title: "Hit the water!",
                  content: "Track your rides, analyze your performance, and make every waterski session count."),
            .init(emoji: "🛰️",
                  title: "Track every run",
                  content: "Use precise GPS to log your waterski sessions, speed, distance, and more."),
            .init(emoji: "📈",
                  title: "Visualize improvement",
                  content: "View detailed stats, charts, and achievements as you improve over time."),
        ]
    }
}
