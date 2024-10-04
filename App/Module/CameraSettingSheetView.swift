//
//  CameraSettingSheetView.swift
//  karashiru
//
//  Created by akidon0000 on 2024/10/04.
//

import SwiftUI

@available(iOS 16.0, *)
struct CameraSettingSheetView: View {
    var body: some View {
        VStack {
            Text("This is a custom sheet")
                .font(.largeTitle)
                .padding()

            Text("You cannot dismiss this by swiping down!")
                .padding()
        }
        .presentationDetents([.height(150), .large])
    }
}
