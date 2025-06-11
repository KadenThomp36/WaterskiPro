import CoreLocation
import SwiftData
import SwiftUI
import SymbolPicker

struct RecordSessionView: View {
    @Query() private var locations: [Location]

    @AppStorage("speed") private var speedUnit = "mph"
    @AppStorage("length") private var lengthUnit = "feet"
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @AppStorage("hasCompletedSignUpFlow") private var hasCompletedSignup = true
    @AppStorage("activeUser") private var activeUser: UUID?

    @Binding var user: Profile
    @Binding var tabSelection: Int

    @State private var iconPickerPresented = false
    @State private var icon = "plus.square.dashed"
    @State private var sessionType: Session.SessionType = .practice
    @State private var isInputAlertShown = false

    @State private var locationName: String = ""
    @State private var location: Location?
    @State private var activeSession: Session?
    @State private var running: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject var locationDataManager = LocationDataManager()

    let generator = UINotificationFeedbackGenerator()

    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                VStack(alignment: .leading) {
                    locationView(geometry: geometry)
                    sessionForm(geometry: geometry)
                }
            }
        }
        .alert(isPresented: $isInputAlertShown) {
            Alert(title: Text("Enter a name for this location"))
        }
    }

    @ViewBuilder
    private func locationView(geometry: GeometryProxy) -> some View {
        switch locationDataManager.locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            Group {
                if let unwrappedLocation = location {
                    MapViewDynamic(location: .constant(unwrappedLocation))
                } else {
                    MapViewDynamic(location: .constant(Location(name: "", latitude: locationDataManager.locationManager.location?.coordinate.latitude ?? 0, longitude: locationDataManager.locationManager.location?.coordinate.longitude ?? 0)))
                }
            }
            .frame(height: geometry.size.height * 0.5)
            .cornerRadius(16)
            .padding(0)
            .mask(LinearGradient(gradient: Gradient(stops: [
                .init(color: .black, location: 0.55),
                .init(color: .clear, location: 1),
            ]), startPoint: .top, endPoint: .bottom))
            .ignoresSafeArea(.all)
            .onAppear {
                locationDataManager.updateLocation()
                checkForCoordinateMatch(margin: 0.01)
            }

            Text("\(locationName)")
                .font(.title)
                .bold()
                .padding(.top, -65.952)
                .padding(.leading)

            Spacer()

        case .restricted, .denied:
            Text("Current location data was restricted or denied.")
        case .notDetermined:
            VStack(alignment: .center) {
                ProgressView("Finding your location...")
                    .scaleEffect(3)
                    .font(.system(size: 8))
                    .frame(width: 150, height: 150)
            }
        default:
            ProgressView()
        }
    }

    @ViewBuilder
    private func sessionForm(geometry: GeometryProxy) -> some View {
        VStack(alignment: .center) {
            Form {
                if location?.name == "" && activeSession == nil {
                    TextField("Location Name", text: $locationName)
                        .padding(.horizontal)
                }
                Picker(selection: $sessionType, label: Text("Session Type")) {
                    ForEach(Session.SessionType.allCases, id: \.self) { sessionType in
                        Text(sessionType.rawValue).tag(sessionType)
                    }
                }
                .pickerStyle(.navigationLink)
                .padding()

                HStack {
                    Spacer()
                    Button(action: {
                        generator.notificationOccurred(.success)
                        activeSession == nil ? startSession() : endSession()
                    }) {
                        Text(activeSession == nil ? "Start Session" : "Stop Session")
                            .frame(maxWidth: .infinity)

                    }
                    .buttonStyle(CustomButtonStyle())
                    Spacer()
                }
            }
            .formStyle(.columns)
            .frame(width: geometry.size.width, height: geometry.size.height * 0.25)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .onAppear {
                locationDataManager.updateLocation()
                checkForCoordinateMatch(margin: 0.01)
                isRunning()
            }
            .sheet(isPresented: $running) {
                NavigationView {
                    PassView(session: activeSession!)
                        .interactiveDismissDisabled(true)
                        .toolbar {
                            ToolbarItem {
                                Button(action: endSession) {
                                    Text("End")
                                }
                            }
                        }
                }
            }
        }
    }

    private func checkForCoordinateMatch(margin: Double) {
        guard let currentLocation = locationDataManager.locationManager.location else { return }
        let latitude = currentLocation.coordinate.latitude
        let longitude = currentLocation.coordinate.longitude
        
        for loc in locations {
            if abs(latitude - loc.latitude) < margin && abs(longitude - loc.longitude) < margin {
                locationName = loc.name
                location = loc
                return
            }
        }
        location = Location(name: "", latitude: latitude, longitude: longitude)
    }

    private func isRunning() {
        if let session = user.sessions.first(where: { $0.active }) {
            activeSession = session
            running = true
        }
    }

    private func endSession() {
        activeSession?.endTime = Date()
        activeSession?.active = false
        activeSession = nil
        running = false
    }

    private func startSession() {
        guard locationName.isEmpty == false || location?.name.isEmpty == false else {
            isInputAlertShown = true
            return
        }

        location?.name = locationName

        withAnimation {
            let newSession = Session(
                startTime: Date(),
                sessionType: sessionType,
                profile: user
            )
            newSession.location = location
            activeSession = newSession
            running = true
            
            modelContext.insert(location!)
            user.sessions.append(newSession)
            try? modelContext.save()
        }
        dismiss()
    }
}

//struct StartButton: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .padding()
//            .background(.blue)
//            .foregroundColor(.white)
//            .clipShape(RoundedRectangle(cornerRadius: 5))
//            .scaleEffect(configuration.isPressed ? 1.2 : 1)
//            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
//    }
//}
