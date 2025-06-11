//
//  ContentView.swift
//  InventoryPro
//
//  Created by Kaden Thompson on 1/3/24.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var session: SessionManager
    
    @Query(sort: \Profile.profileCreationDate, order: .reverse) private var users: [Profile]

    @AppStorage("activeUser") private var activeUser: UUID?

    @State var loggedInUser: Profile = Profile()
    @State private var avatarImage: UIImage?
    @State var animate = false
    @State private var tabSelection = 2
    @State private var loggedIn = false

    var body: some View {
            if (!loggedIn) {
                VStack {
                    ContentUnavailableView {
                        Label(users.isEmpty ? "Add your profile!" : "No users logged in!", systemImage: "person.crop.circle")
                            .symbolEffect(.pulse, options: .repeat(3), value: animate)
                            .task {
                                animate = true
                            }
                    } description: {
                        Text(users.isEmpty ? "Get started by adding a new user" : "Get started by logging in or adding a new user")
                    } actions: {
                        Button("Add A User") {
                            session.completeOnboarding()
                        }
                            ForEach(users) { user in
                                Button(action: {
                                    activeUser = user.id
                                    login()
                                }, label: {
                                    Image(uiImage: getImage(imageData: user.profilePicture))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 25, height: 25)
                                        .clipShape(.circle)
                                    Text("\(user.name)")
                                })
                            }
                        
                    }
                }
                .onAppear {
                    login()
                }
            } else {
                loggedInHomeView
            }
    }
    
    private func login() {
        let userProfile = getActiveUser(activeUser: activeUser ?? UUID(), users: users)
        if (userProfile.found) {
            activeUser = userProfile.user.id
            loggedInUser = userProfile.user
            loggedIn = true
        } else {
            activeUser = UUID()
            loggedInUser = Profile()
            loggedIn = false
        }
    }
    
    private func logout() {
        print("logout has been called")
        activeUser = UUID()
        loggedInUser = Profile()
        loggedIn = false
    }
}

extension HomeView {
 
    var loggedInHomeView: some View {
        TabView(selection: $tabSelection) {
            SessionView(user: $loggedInUser, tabSelection: $tabSelection)
                .navigationTitle("Sessions")
                .tabItem { Label("Sessions", systemImage: "list.clipboard") }
                .tag(1)
            RecordSessionView(user: $loggedInUser, tabSelection: $tabSelection)
                .navigationTitle("Record")
                .tabItem { Label("Record", systemImage: "record.circle") }
                .tag(2)
            StatsOverviewView(user: $loggedInUser, tabSelection: $tabSelection)
                .navigationTitle("Stats")
                .tabItem { Label("Stats", systemImage: "chart.xyaxis.line") }
                .tag(3)
            SettingsView(user: $loggedInUser) {
                logout()
            }
                .navigationTitle("Settings")
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(4)
        }
    }
    

}

//#Preview {
//    ContentView()
//        .modelContainer(for: Pass.self, inMemory: false)
//}
