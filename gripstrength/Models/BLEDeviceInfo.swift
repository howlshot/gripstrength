//
//  BLEDeviceInfo.swift
//  gripstrength
//
//  Data model for discovered BLE devices
//

import Foundation
import CoreBluetooth

struct BLEDeviceInfo: Identifiable, Equatable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    let rssi: Int
    let advertisementData: [String: Any]

    var isJamarDevice: Bool {
        name.lowercased().contains("jamar") ||
        name.lowercased().contains("smart")
    }

    var signalStrength: SignalStrength {
        switch rssi {
        case -50...0: return .excellent
        case -60..<(-50): return .good
        case -70..<(-60): return .fair
        default: return .weak
        }
    }

    static func == (lhs: BLEDeviceInfo, rhs: BLEDeviceInfo) -> Bool {
        lhs.id == rhs.id
    }
}

enum SignalStrength {
    case excellent
    case good
    case fair
    case weak

    var iconName: String {
        switch self {
        case .excellent: return "wifi"
        case .good: return "wifi"
        case .fair: return "wifi"
        case .weak: return "wifi.exclamationmark"
        }
    }

    var bars: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .fair: return 2
        case .weak: return 1
        }
    }
}
