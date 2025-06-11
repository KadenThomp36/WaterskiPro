//
//  CategoryListView.swift
//  InventoryPro
//
//  Created by Kaden Thompson on 1/5/24.
//

import SwiftData
import SwiftUI
// TODO: Look into Guages for displaying on link view
struct SessionView: View {
    @Environment(\.modelContext) var modelContext

    @AppStorage("activeUser") private var activeUser: UUID?

    @Binding var user: Profile
    @Binding var tabSelection: Int

    @State var animate = false

    var body: some View {
        NavigationStack {
            if user.sessions.isEmpty {
                VStack {
                    ContentUnavailableView {
                        Label("No sessions added yet!", systemImage: "list.clipboard")
                            .symbolEffect(.pulse, options: .repeat(3), value: animate)
                            .task {
                                animate = true
                            }
                    } description: {
                        Text("Get started by adding your first session")
                    } actions: {
                        Button("Add A Session") {
                            tabSelection = 2
                        }
                    }
                }
            } else {
                SessionListView
            }
        }
    }
}

extension SessionView {
    var groups: [[Session]] {
        let dictionary: [Date: [Session]] = Dictionary(grouping: user.sessions, by: { Calendar.current.startOfDay(for: $0.startTime) })
        // Sort sessions within each group by start time
        let sortedDictionary = dictionary.mapValues { $0.sorted(by: { $0.startTime > $1.startTime }) }

        // Sort groups by the start date of the first session in each group
        let sortedGroups = sortedDictionary.sorted { $0.key > $1.key }

        return sortedGroups.map { $0.value }
    }

    private var SessionListView: some View {
        ZStack {
            List {
                ForEach(groups, id: \.self) { sessionGroup in
                    Section(header: Text("\(sessionGroup[0].startTime, format: Date.FormatStyle(date: .abbreviated))")
                        .font(.title)
                        .fontWeight(.black)) {
                            ForEach(sessionGroup, id: \.self) { session in
                                NavigationLink {
                                    PassView(session: session)
                                        .navigationTitle("\(session.startTime, format: Date.FormatStyle(date: .abbreviated, time: .omitted))")
                                } label: {
                                    SessionLinkView(session: session)
                                }
                            }
                            .onDelete { offsets in
                                deleteItems(offsets: offsets, in: sessionGroup)
                            }
                        }
                }
            }

        }
    }

    private func deleteItems(offsets: IndexSet, in sessionGroup: [Session]) {
        withAnimation {
            for index in offsets {
                let sessionToDelete = sessionGroup[index]
                if let globalIndex = user.sessions.firstIndex(of: sessionToDelete) {
                    user.sessions.remove(at: globalIndex)
                }
            }
        }
    }
}

// #Preview {
//    SessionView(tabSelection: 2)
//        .modelContainer(for: Session.self, inMemory: false)
// }
