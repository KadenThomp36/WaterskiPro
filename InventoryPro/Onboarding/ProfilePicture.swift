//
//  ProfilePicture.swift
//  Waterski Pro
//
//  Created by Kaden Thompson on 4/28/24.
//

import SwiftUI
import PhotosUI

struct ProfilePicture: View {
    @Binding var gender: Gender
    @Binding var profilePicture: Data
    let action: () -> Void

    @State private var avatarImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .frame(width: 220, height: 220)
                    .foregroundColor(.waterSecondary)
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    Image(uiImage: avatarImage ?? UIImage(resource: .defaultAvatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipShape(.circle)
                }
            }
            Text("Gender")
                .font(.system(size: 30,
                              weight: .bold,
                              design: .rounded))
                .foregroundColor(.waterAccent)
            
            Picker(selection: $gender, label: Text("Picker")) {
                Text("Select An Option")
                Text("Male").tag(Gender.male)
                Text("Female").tag(Gender.female)
            }
            .pickerStyle(.automatic)
            .padding()
            .frame(width: 350, height: 50)
            .background(.waterPrimary, in: RoundedRectangle(cornerRadius: 10,
                                                     style: .continuous))
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .padding(.bottom, 8)
            
            Button("Start Tracking") {
                action()
            }
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .padding(.horizontal, 60)
            .padding(.vertical, 15)
            .background(.waterPrimary, in: RoundedRectangle(cornerRadius: 10,
                                                     style: .continuous))
            .foregroundColor(.waterTextInverse)
            .padding(.top, 40)
        }
        .onChange(of: photosPickerItem) { _, _ in
            Task {
                if let photosPickerItem,
                   let data = try? await photosPickerItem.loadTransferable(type: Data.self) {
                    profilePicture = data
                    if let image = UIImage(data: data) {
                        avatarImage = image
                    }
                }
                photosPickerItem = nil
            }
        }
    }
}

#Preview {
    ProfilePicture(gender: .constant(.female), profilePicture: .constant(Data())) {}
        .padding()
        .previewLayout(.sizeThatFits)
        .background(.waterBackground)
}
