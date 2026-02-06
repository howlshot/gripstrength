//
//  DeviceConnectionViewModel.swift
//  gripstrength
//
//  View model for device scanning and connection
//

import Foundation
import CoreBluetooth

@MainActor
@Observable
final class DeviceConnectionViewModel {
    // MARK: - Properties

    private let bluetoothManager: BluetoothManager

    // MARK: - Computed Properties

    var connectionState: ConnectionState {
        bluetoothManager.connectionState
    }

    var discoveredDevices: [BLEDeviceInfo] {
        bluetoothManager.discoveredDevices
    }

    var isScanning: Bool {
        connectionState == .scanning
    }

    var isConnected: Bool {
        connectionState.isConnected
    }

    var connectedDeviceName: String? {
        bluetoothManager.connectedPeripheral?.name
    }

    var canStartScan: Bool {
        connectionState == .poweredOn || connectionState == .disconnected
    }

    // MARK: - Initialization

    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
    }

    // MARK: - Actions

    func startScanning() {
        bluetoothManager.startScanning()
    }

    func stopScanning() {
        bluetoothManager.stopScanning()
    }

    func connect(to device: BLEDeviceInfo) {
        bluetoothManager.connect(to: device)
    }

    func disconnect() {
        bluetoothManager.disconnect()
    }
}
