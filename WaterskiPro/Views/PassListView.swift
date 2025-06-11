//
//  ItemListView.swift
//  InventoryPro
//
//  Created by Kaden Thompson on 1/5/24.
//

import SwiftData
import SwiftUI

struct PassView: View {
    @Environment(\.modelContext) private var modelContext
    
    let session: Session
    @State private var showingAddPass = false

    @State private var showingEditSession = false
    @State private var editedStart: Date = Date()
    @State private var editedEnd: Date = Date()
    @State private var editedLocation: Location = Location(name: "", latitude: 0, longitude: 0)
    @State private var editedSessionType: Session.SessionType = .practice

    @State private var newPass: Pass?
    @State private var animate = false

    @Query() var locations: [Location]
    var body: some View {
        VStack(alignment: .leading) {
            MapView(lat: session.location?.latitude ?? 0.0, long: session.location?.longitude ?? 0.0)
                .frame(height: 100)
                .cornerRadius(25)
                .padding([.horizontal, .top])
            Text("\(session.location?.name ?? "No Name")")
                .font(.title)
                .bold()
                .padding(.leading)
            Text("\(session.startTime, format: .dateTime)")
                .padding(.leading)
            if session.passes.isEmpty {
                VStack(alignment: .leading) {
                    ContentUnavailableView {
                        Label("No passes added yet!", systemImage: "skis")
                            .symbolEffect(.pulse, options: .repeat(3), value: animate)
                            .task {
                                animate = true
                            }
                    } description: {
                        Text("Log Your first pass")
                    } actions: {
                        Button("Add a pass") {
                            showingAddPass.toggle()
                        }
                    }
                }
            } else {
                PassListView
            }
        }
        .onAppear {
            editedStart = session.startTime
            editedSessionType = session.sessionType
            
            if (session.location != nil) {
                editedLocation = session.location!
            }
            if (session.endTime != nil) {
                editedEnd = session.endTime!
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSession.toggle()
                }
            }
        }
        .sheet(isPresented: $showingAddPass, content: {
            AddPassView(session: session)
                .presentationDetents([.medium])
                .presentationDragIndicator(.automatic)
        })
        .sheet(isPresented: $showingEditSession, content: {
            Form {
                DatePicker("Start Time", selection: $editedStart, displayedComponents: [.hourAndMinute])
                if (session.endTime != nil) {
                    DatePicker("End Time", selection: $editedEnd, displayedComponents: [.hourAndMinute])
                }
                Picker(selection: $editedSessionType, label: Text("Session Type")) {
                    ForEach(Session.SessionType.allCases, id: \.self) { sessionType in
                        Text(sessionType.rawValue).tag(sessionType)
                    }
                }
                Picker(selection: $editedLocation, label: Text("Location")) {
                    ForEach(locations, id: \.self) { location in
                        Text("\(location.name)").tag(location)
                    }
                }
                Button("Continue") {
                    saveEdits()
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(width: 300, height: 50)
                .background(.waterPrimary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundColor(.waterText)
            }
        })
        .presentationDetents([.medium])
    }

    func saveEdits() {
        session.startTime = editedStart
        session.location = editedLocation
        session.sessionType = editedSessionType
        
        if (session.endTime != nil) {
            session.endTime = editedEnd
        }
        showingEditSession.toggle()
    }
}

extension PassView {
    private var PassListView: some View {
        List {
            ForEach(session.passes.sorted(by: { $0.timestamp > $1.timestamp })) { pass in
                NavigationLink {
                    PassDetailView(pass: pass)
                        .navigationTitle("\(pass.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .omitted))")
                } label: {
                    PassLinkView(pass: pass)
                }
            }
            .onDelete(perform: deleteItems)
            .listRowSeparator(.hidden)
        }
        .navigationTitle("Passes")
        .toolbar {
            ToolbarItem {
                Button(action: {
                    showingAddPass.toggle()
                }) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(session.passes[index])
            }
        }
    }
}

#Preview("Selected Category") {
    let profile = Profile(name: "Kaden", gender: .female, dateOfBirth: Date(timeIntervalSinceReferenceDate: 0), profilePicture: Data(), prefSpeed: 0, prefLength: 0)
    var session = Session(startTime: Date(), sessionType: .practice, profile: profile)
    session.location?.latitude = 43.153030
    session.location?.longitude = -83.800520
    return PassView(session: session)
}
