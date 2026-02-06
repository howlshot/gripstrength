//
//  GripReading.swift
//  gripstrength
//
//  Data model for grip force readings
//

import Foundation

struct GripReading: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let force: Double // in pounds (lbs)

    var forceInKg: Double {
        force * 0.453592
    }
}

// MARK: - Hand & Trial Tracking

enum Hand: String, CaseIterable {
    case dominant = "Dominant"
    case nonDominant = "Non-Dominant"
}

struct HandTrial: Identifiable, Equatable {
    let id = UUID()
    let trialNumber: Int // 1, 2, or 3
    let peakForce: Double // in pounds
    let timestamp: Date

    var forceInKg: Double {
        peakForce * 0.453592
    }
}

struct HandTrials: Equatable {
    var trials: [HandTrial] = []

    var isFull: Bool { trials.count >= 3 }
    var count: Int { trials.count }

    var average: Double? {
        guard !trials.isEmpty else { return nil }
        return trials.map(\.peakForce).reduce(0, +) / Double(trials.count)
    }

    var best: Double? {
        trials.map(\.peakForce).max()
    }

    mutating func addTrial(peakForce: Double) {
        guard !isFull else { return }
        let trial = HandTrial(
            trialNumber: trials.count + 1,
            peakForce: peakForce,
            timestamp: Date()
        )
        trials.append(trial)
    }

    mutating func reset() {
        trials.removeAll()
    }
}

// MARK: - Force Unit

enum ForceUnit: String, CaseIterable {
    case pounds = "lbs"
    case kilograms = "kg"

    var displayName: String {
        switch self {
        case .pounds: return "Pounds"
        case .kilograms: return "Kilograms"
        }
    }

    var abbreviation: String {
        rawValue
    }
}
