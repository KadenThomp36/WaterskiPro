//
//  AddItemView.swift
//  InventoryPro
//
//  Created by Kaden Thompson on 1/4/24.
//

import Combine
import PhotosUI
import SwiftData
import SwiftUI

struct AddPassView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("speed") private var speed = "mph"
    @AppStorage("length") private var length = "feet"

    @ObservedObject var session: Session

    @State private var timestamp: Date = Date()
    @State private var bouys: Double = 3
    @State private var ropeLength: Double = 0
    @State private var boatSpeed: Int = 0
    @State private var completion: Pass.Completion = .failedNoFall
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            VStack {
                Text("\(bouys, format: .number.rounded(increment: 0.1)) @ \(convertedBoatSpeed()[boatSpeed], format: .number.rounded(increment: 0.1)) \(speed.uppercased()) \(convertRopeLength()[Int(ropeLength)], format: .number.rounded(increment: 0.1))\(length == "feet" ? "'" : "m") off")
                    .font(.headline)
                Text("\(completion.rawValue)")
                    .font(.subheadline)
                GeometryReader { geometry in
                    Form {
                        Section {
                            HStack(spacing: 0) {
                                Picker(selection: $bouys, label: Text("Bouys")) {
                                    ForEach(bouysRange, id: \.self) { bouy in
                                        let roundedBouy = String(format: "%.1f", bouy)
                                        Image("\(roundedBouy)")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: geometry.size.width * 0.45, height: 75)
                                .onChange(of: bouys) { oldValue, newValue in
                                    if oldValue == 6 && newValue == 5.5 {
                                        completion = .failedNoFall
                                    }

                                    if oldValue == 5.5 && newValue == 6 {
                                        completion = .clean
                                    }
                                }

                                Text("@")

                                Picker(selection: $boatSpeed, label: Text("Boat Speed")) {
                                    ForEach(boatSpeedRoapLengthRAW, id: \.self) { speed in
                                        Text("\(convertedBoatSpeed()[speed], format: .number.rounded(increment: 0.1))").tag(speed)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: geometry.size.width * 0.2, height: 75)

                                Text("\(speed)")
                                Spacer()
                            }
                            .listRowSeparator(.hidden)

                            Slider(
                                value: $ropeLength,
                                in: rangeRoapLength,
                                step: 1
                            ) {
                                Text("Speed")
                            } onEditingChanged: { editing in
                                isEditing = editing
                            }
                            .accentColor(ropeColor(ropeLength: Int(ropeLength)))
                            .onChange(of: ropeLength) {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            }
                            .onAppear {
                                if session.passes.isEmpty {
                                    print("No passes added, reading from pref")
                                    boatSpeed = session.profile!.prefSpeed
                                    ropeLength = session.profile!.prefLength
                                } else {
                                    let sortedPasses = session.passes.sorted(by: { $0.timestamp > $1.timestamp })
                                    boatSpeed = sortedPasses.first!.boatSpeed
                                    ropeLength = Double(sortedPasses.first!.ropeLength)
                                }
                                let thumbImage = UIImage(systemName: "circle.fill")
                                UISlider.appearance().setThumbImage(thumbImage, for: .normal)
                            }

                            Picker(selection: $completion, label: Text("Completion")) {
//                                ForEach(Pass.Completion.allCases, id: \.self) { completion in
//                                    Text(completion.rawValue).tag(completion)
//                                }
                                if bouys == 6 {
                                    Text(Pass.Completion.clean.rawValue).tag(Pass.Completion.clean)
                                    Text(Pass.Completion.sloppy.rawValue).tag(Pass.Completion.sloppy)
                                } else {
                                    Text(Pass.Completion.failedFall.rawValue).tag(Pass.Completion.failedFall)
                                    Text(Pass.Completion.failedNoFall.rawValue).tag(Pass.Completion.failedNoFall)
                                }
                            }
                            .pickerStyle(.navigationLink)
                        }
                    }
                    .scrollDisabled(true)
                }
                Button {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    addPass()
                    dismiss()
                } label: {
                    Text("Save")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(-2.0)
                }
                .padding()
                .buttonStyle(.borderedProminent)
            }
            .padding(.top)
        }
    }

    private func addPass() {
        let currentDate = Date()
        let newPass: Pass = Pass(
            session: session,
            timestamp: currentDate,
            bouys: bouys,
            ropeLength: Int(ropeLength),
            boatSpeed: boatSpeed,
            completion: completion,
            pointsRaw: getZBS(rLength: Int(ropeLength), bSpeed: boatSpeed, bouys: bouys)
        )
        newPass.notes = ""
        session.passes.append(newPass)
    }
}

#Preview {
    let profile = Profile(name: "Kaden", gender: .female, dateOfBirth: Date(timeIntervalSinceReferenceDate: 0), profilePicture: Data(), prefSpeed: 0, prefLength: 0)
    let session1 = Session(startTime: Date(), sessionType: .practice, profile: profile)
    return AddPassView(session: session1)
}
