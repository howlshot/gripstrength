//
//  ContentView.swift
//  gripstrength
//
//  Main content view with tab navigation
//

import SwiftUI

struct ContentView: View {
    @Environment(BluetoothManager.self) private var bluetoothManager
    @State private var selectedTab = 0
    @State private var viewModel: LiveReadingViewModel?
    @State private var resultsStore = ResultsStore()

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.needle")
                }
                .tag(0)

            if let viewModel = viewModel {
                ResultsView(viewModel: viewModel, resultsStore: resultsStore)
                    .tabItem {
                        Label("Results", systemImage: "chart.bar.fill")
                    }
                    .tag(1)
            }

            HistoryView(resultsStore: resultsStore)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)

            DeviceScanView()
                .tabItem {
                    Label("Devices", systemImage: "antenna.radiowaves.left.and.right")
                }
                .tag(3)
        }
        .tint(Theme.gold)
        .preferredColorScheme(.dark)
        .onAppear {
            if viewModel == nil {
                viewModel = LiveReadingViewModel(bluetoothManager: bluetoothManager)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(BluetoothManager())
}
