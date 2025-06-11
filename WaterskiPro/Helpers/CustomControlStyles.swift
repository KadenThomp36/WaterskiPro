//
//  CustomControlStyles.swift
//  Waterski Pro
//
//  Created by Kaden Thompson on 6/23/24.
//

import Foundation
import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .background(.waterPrimary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundColor(.waterTextInverse)
    }
}
