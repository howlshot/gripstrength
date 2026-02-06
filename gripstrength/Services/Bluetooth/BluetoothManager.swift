//
//  BluetoothManager.swift
//  gripstrength
//
//  Core Bluetooth manager for scanning and connecting to BLE devices
//

import Foundation
import CoreBluetooth
import Combine

// MARK: - Connection State

enum ConnectionState: Equatable {
    case unknown
    case poweredOff
    case poweredOn
    case scanning
    case connecting
    case connected
    case disconnected

    var displayText: String {
        switch self {
        case .unknown: return "Unknown"
        case .poweredOff: return "Bluetooth Off"
        case .poweredOn: return "Ready"
        case .scanning: return "Scanning..."
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        }
    }

    var isConnected: Bool {
        self == .connected
    }
}

// MARK: - BLE Constants

enum BLEConstants {
    // Nordic UART Service UUIDs
    static let nordicUARTServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let nordicUARTTXCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    static let nordicUARTRXCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
}

// MARK: - Bluetooth Manager

@MainActor
@Observable
final class BluetoothManager: NSObject {
    // MARK: - Published Properties

    private(set) var connectionState: ConnectionState = .unknown
    private(set) var discoveredDevices: [BLEDeviceInfo] = []
    private(set) var connectedPeripheral: CBPeripheral?
    private(set) var txCharacteristic: CBCharacteristic?

    // MARK: - Publishers

    let forceReadingPublisher = PassthroughSubject<Double, Never>()

    // MARK: - Private Properties

    private var centralManager: CBCentralManager!
    private var shouldAutoReconnect = true
    private var lastConnectedDeviceIdentifier: UUID?
    private var dataBuffer: String = ""

    // Debug: stores last raw BLE string for diagnostics
    private(set) var lastRawData: String = ""

    // MARK: - Initialization

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Public Methods

    func startScanning() {
        guard connectionState == .poweredOn || connectionState == .disconnected else { return }

        discoveredDevices.removeAll()
        connectionState = .scanning

        // Scan for devices advertising the Nordic UART Service
        centralManager.scanForPeripherals(
            withServices: [BLEConstants.nordicUARTServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        // Also scan without filter to find all devices (in case service isn't advertised)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self, self.discoveredDevices.isEmpty else { return }
            self.centralManager.scanForPeripherals(
                withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )
        }
    }

    func stopScanning() {
        centralManager.stopScan()
        if connectionState == .scanning {
            connectionState = .poweredOn
        }
    }

    func connect(to device: BLEDeviceInfo) {
        stopScanning()
        connectionState = .connecting
        lastConnectedDeviceIdentifier = device.peripheral.identifier
        centralManager.connect(device.peripheral, options: nil)
    }

    func disconnect() {
        shouldAutoReconnect = false
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        txCharacteristic = nil
        connectionState = .disconnected
    }

    func enableAutoReconnect() {
        shouldAutoReconnect = true
    }

    // MARK: - Private Methods

    private func handleReceivedData(_ data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return }

        lastRawData = string
        print("[BLE RAW] \(string.debugDescription)")

        // Append to buffer for handling fragmented messages
        dataBuffer += string

        // Process complete messages (delimited by newline or "::" prefix)
        processBuffer()
    }

    private func processBuffer() {
        // Split buffer on newlines to find complete messages
        let lines = dataBuffer.components(separatedBy: .newlines)

        // Keep the last element as it may be incomplete
        if lines.count > 1 {
            // Process all complete lines
            for i in 0..<(lines.count - 1) {
                let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                if !line.isEmpty, let force = DataParser.parseJamarData(line) {
                    print("[BLE PARSED] force = \(force) lbs")
                    forceReadingPublisher.send(force)
                }
            }
            // Keep remainder in buffer
            dataBuffer = lines.last ?? ""
        }

        // Also try to parse the buffer directly if it contains "::VAL"
        // (handles case where data arrives without newlines)
        if dataBuffer.contains("::VAL") {
            if let force = DataParser.parseJamarData(dataBuffer) {
                print("[BLE PARSED] force = \(force) lbs (from buffer)")
                forceReadingPublisher.send(force)
                dataBuffer = ""
            }
        }

        // Prevent buffer from growing indefinitely
        if dataBuffer.count > 500 {
            dataBuffer = String(dataBuffer.suffix(100))
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .unknown:
                connectionState = .unknown
            case .resetting:
                connectionState = .unknown
            case .unsupported:
                connectionState = .unknown
            case .unauthorized:
                connectionState = .unknown
            case .poweredOff:
                connectionState = .poweredOff
            case .poweredOn:
                connectionState = .poweredOn
            @unknown default:
                connectionState = .unknown
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown Device"

            let deviceInfo = BLEDeviceInfo(
                id: peripheral.identifier,
                peripheral: peripheral,
                name: name,
                rssi: RSSI.intValue,
                advertisementData: advertisementData
            )

            // Update or add device
            if let index = discoveredDevices.firstIndex(where: { $0.id == deviceInfo.id }) {
                discoveredDevices[index] = deviceInfo
            } else {
                discoveredDevices.append(deviceInfo)
            }

            // Sort by signal strength
            discoveredDevices.sort { $0.rssi > $1.rssi }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            connectedPeripheral = peripheral
            peripheral.delegate = self
            peripheral.discoverServices([BLEConstants.nordicUARTServiceUUID])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            connectionState = .disconnected
            connectedPeripheral = nil
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            connectionState = .disconnected
            connectedPeripheral = nil
            txCharacteristic = nil

            // Auto-reconnect if enabled
            if shouldAutoReconnect, let identifier = lastConnectedDeviceIdentifier {
                let peripherals = central.retrievePeripherals(withIdentifiers: [identifier])
                if let peripheral = peripherals.first {
                    connectionState = .connecting
                    central.connect(peripheral, options: nil)
                }
            }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            guard error == nil else {
                connectionState = .disconnected
                return
            }

            if let service = peripheral.services?.first(where: { $0.uuid == BLEConstants.nordicUARTServiceUUID }) {
                peripheral.discoverCharacteristics(
                    [BLEConstants.nordicUARTTXCharacteristicUUID],
                    for: service
                )
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            guard error == nil else {
                connectionState = .disconnected
                return
            }

            if let txChar = service.characteristics?.first(where: { $0.uuid == BLEConstants.nordicUARTTXCharacteristicUUID }) {
                txCharacteristic = txChar
                peripheral.setNotifyValue(true, for: txChar)
                connectionState = .connected
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            guard error == nil, let data = characteristic.value else { return }
            handleReceivedData(data)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        Task { @MainActor in
            if error != nil {
                connectionState = .disconnected
            }
        }
    }
}
