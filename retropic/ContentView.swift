//
//  ContentView.swift
//  retropic
//
//  Created by Kolby De Aguiar on 4/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("RetroPic")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                NavigationLink("Camera", destination: CameraView())
                    .buttonStyle(.borderedProminent)

                NavigationLink("Library", destination: LibraryView())
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
    



#Preview {
    ContentView()
}
