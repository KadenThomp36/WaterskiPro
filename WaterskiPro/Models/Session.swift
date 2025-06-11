//
//  ItemCategory.swift
//  InventoryPro
//
//  Created by Kaden Thompson on 1/4/24.
//

import CoreLocation
import Foundation
import SwiftData

@Model
final class Session: ObservableObject {
    @Attribute(.unique) var id = UUID()
    @Relationship(deleteRule: .cascade, inverse: \Pass.session)
    var passes: [Pass] = []
    var profile: Profile?
    var startTime: Date
    var endTime: Date?
    var notes: String?
    var location: Location?
    var active: Bool
    
    var sessionLength: DateComponents {
        let calendar = Calendar.current
        guard let endTime else { return calendar.dateComponents([.minute], from: startTime, to: Date()) }
        let components = calendar.dateComponents([.hour, .minute], from: startTime, to: endTime)
        return components
    }

    var sessionType: SessionType

    init(startTime: Date, sessionType: SessionType, profile: Profile) {
        self.profile = profile
        self.startTime = startTime
        self.sessionType = sessionType
        active = true
    }
}

extension Session {
    enum SessionType: String, CaseIterable, Codable {
        case practice = "Practice"
        case tournament = "Tournament"
    }
}

extension Session {
    // Mock Data
    @MainActor
    static var preview: ModelContainer {
        let container = try! ModelContainer(for: Session.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

        let profile = Profile(name: "Kaden", gender: .female, dateOfBirth: Date(timeIntervalSinceReferenceDate: 0), profilePicture: Data(), prefSpeed: 0, prefLength: 0)

        let session1 = Session(startTime: Date(), sessionType: .practice, profile: profile)
        let session2 = Session(startTime: Date(), sessionType: .tournament, profile: profile)

        let child1 = Pass(session: session1, timestamp: Date(), bouys: 0.0, ropeLength: 0, boatSpeed: 0, completion: .clean, pointsRaw: 50.0)
        let child2 = Pass(session: session2, timestamp: Date(), bouys: 0.0, ropeLength: 0, boatSpeed: 0, completion: .failedFall, pointsRaw: 50.0)

        container.mainContext.insert(child1)
        container.mainContext.insert(child2)

        return container
    }
}
