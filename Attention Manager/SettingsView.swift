//
//  SettingsView.swift
//  Attention Manager
//
//  Created by Shawn Carolan on 9/11/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("googleSheetURL") private var googleSheetURL = ""
    @State private var isAuthenticated = false

    var body: some View {
        Form {
            Section(header: Text("Google Sheet Settings")) {
                TextField("Google Sheet URL", text: $googleSheetURL)
                Button(isAuthenticated ? "Authenticated" : "Authenticate with Google") {
                    GoogleSheetsLogger.shared.authenticate { success in
                        isAuthenticated = success
                    }
                }
                .disabled(isAuthenticated)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}
