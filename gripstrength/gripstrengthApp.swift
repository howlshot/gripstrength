//
//  gripstrengthApp.swift
//  gripstrength
//
//  Main app entry point
//

import SwiftUI

@main
struct gripstrengthApp: App {
    @State private var bluetoothManager = BluetoothManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(bluetoothManager)
        }
    }
}
