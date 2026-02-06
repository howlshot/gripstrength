//
//  DeviceScanView.swift
//  gripstrength
//
//  View for scanning and connecting to BLE devices
//

import SwiftUI

struct DeviceScanView: View {
    @Environment(BluetoothManager.self) private var bluetoothManager
    @State private var viewModel: DeviceConnectionViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if let viewModel = viewModel {
                    DeviceScanContent(viewModel: viewModel)
                } else {
                    ProgressView()
                        .tint(Theme.gold)
                }
            }
            .navigationTitle("Devices")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = DeviceConnectionViewModel(bluetoothManager: bluetoothManager)
            }
        }
    }
}

private struct DeviceScanContent: View {
    @Bindable var viewModel: DeviceConnectionViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingLG) {
                // Connection status card
                if viewModel.isConnected {
                    ConnectedDeviceCard(
                        deviceName: viewModel.connectedDeviceName ?? "Jamar Smart",
                        onDisconnect: { viewModel.disconnect() }
                    )
                }

                // Scan section
                VStack(spacing: Theme.spacingMD) {
                    // Scan button
                    ScanButton(
                        isScanning: viewModel.isScanning,
                        canScan: viewModel.canStartScan,
                        onTap: {
                            if viewModel.isScanning {
                                viewModel.stopScanning()
                            } else {
                                viewModel.startScanning()
                            }
                        }
                    )

                    // Status text
                    if viewModel.connectionState == .poweredOff {
                        HStack(spacing: Theme.spacingSM) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Theme.warning)
                            Text("Please enable Bluetooth in Settings")
                                .font(Theme.bodyFont)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.cardBackground)
                        .cornerRadius(Theme.cornerRadiusMD)
                    }
                }

                // Discovered devices
                if !viewModel.discoveredDevices.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.spacingSM) {
                        Text("NEARBY DEVICES")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.horizontal, Theme.spacingXS)

                        ForEach(viewModel.discoveredDevices) { device in
                            DeviceCard(
                                device: device,
                                isConnecting: viewModel.connectionState == .connecting,
                                onConnect: { viewModel.connect(to: device) }
                            )
                        }
                    }
                } else if viewModel.isScanning {
                    VStack(spacing: Theme.spacingMD) {
                        ProgressView()
                            .tint(Theme.gold)
                            .scaleEffect(1.5)

                        Text("Searching for devices...")
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacingXXL)
                }
            }
            .padding(Theme.spacingMD)
        }
    }
}

// MARK: - Subviews

private struct ConnectedDeviceCard: View {
    let deviceName: String
    let onDisconnect: () -> Void

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.success.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.success)
            }

            // Info
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                Text(deviceName)
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: Theme.spacingXS) {
                    Circle()
                        .fill(Theme.success)
                        .frame(width: 8, height: 8)
                    Text("Connected")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.success)
                }
            }

            Spacer()

            // Disconnect button
            Button(action: onDisconnect) {
                Text("Disconnect")
                    .font(Theme.labelFont)
                    .foregroundStyle(Theme.error)
                    .padding(.horizontal, Theme.spacingMD)
                    .padding(.vertical, Theme.spacingSM)
                    .background(
                        Capsule()
                            .stroke(Theme.error.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .padding(Theme.spacingMD)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadiusLG)
    }
}

private struct ScanButton: View {
    let isScanning: Bool
    let canScan: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.spacingSM) {
                if isScanning {
                    ProgressView()
                        .tint(Theme.background)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(isScanning ? "Stop Scanning" : "Scan for Devices")
                    .font(Theme.headlineFont)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingMD)
            .background(
                isScanning ? Theme.cardBackground : Theme.gold
            )
            .foregroundStyle(isScanning ? Theme.gold : Theme.background)
            .cornerRadius(Theme.cornerRadiusLG)
        }
        .disabled(!canScan && !isScanning)
        .opacity((!canScan && !isScanning) ? 0.5 : 1)
    }
}

private struct DeviceCard: View {
    let device: BLEDeviceInfo
    let isConnecting: Bool
    let onConnect: () -> Void

    var body: some View {
        Button(action: onConnect) {
            HStack(spacing: Theme.spacingMD) {
                // Signal indicator
                SignalIndicator(strength: device.signalStrength)

                // Device info
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(device.name)
                        .font(Theme.headlineFont)
                        .foregroundStyle(Theme.textPrimary)

                    if device.isJamarDevice {
                        Text("Jamar Dynamometer")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.gold)
                    }
                }

                Spacer()

                // Connect indicator
                if isConnecting {
                    ProgressView()
                        .tint(Theme.gold)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(Theme.spacingMD)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusLG)
                    .stroke(device.isJamarDevice ? Theme.gold.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(isConnecting)
    }
}

private struct SignalIndicator: View {
    let strength: SignalStrength

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(1...4, id: \.self) { bar in
                RoundedRectangle(cornerRadius: 1)
                    .fill(bar <= strength.bars ? Theme.gold : Theme.textTertiary.opacity(0.3))
                    .frame(width: 4, height: CGFloat(bar * 4 + 4))
            }
        }
        .frame(width: 24, height: 24)
    }
}

#Preview {
    DeviceScanView()
        .environment(BluetoothManager())
        .preferredColorScheme(.dark)
}
