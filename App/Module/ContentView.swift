//
//  ContentView.swift
//  karashiru
//
//  Created by akidon0000 on 2024/09/27.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowModal = true

    var body: some View {
        ZStack {
            CameraView()
                .sheet(isPresented: $isShowModal) {
                    CameraSettingSheetView()
                        .interactiveDismissDisabled(true)
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
