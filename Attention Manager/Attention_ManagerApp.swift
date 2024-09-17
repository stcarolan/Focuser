//
//  Attention_ManagerApp.swift
//  Attention Manager
//
//  Created by Shawn Carolan on 8/17/24.
//

import SwiftUI
import AppKit

@main
struct Attention_ManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 300, height: 60)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.level = .floating
            window.styleMask.remove(.titled)
            window.isMovableByWindowBackground = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            
            // Allow window to resize based on content
            window.contentMinSize = NSSize(width: 250, height: 60)
            window.contentMaxSize = NSSize(width: 650, height: 60)
            window.setContentSize(NSSize(width: 300, height: 60))
        }
    }
}
