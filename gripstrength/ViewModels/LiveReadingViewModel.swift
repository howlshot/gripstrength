//
//  LiveReadingViewModel.swift
//  gripstrength
//
//  View model for real-time grip force display
//

import Foundation
import Combine

@MainActor
@Observable
final class LiveReadingViewModel {
    // MARK: - Properties

    private(set) var currentForce: Double = 0.0
    private(set) var peakForce: Double = 0.0
    private(set) var readings: [GripReading] = []
    var selectedUnit: ForceUnit = .pounds

    // MARK: - Hand Trials

    private(set) var selectedHand: Hand = .dominant
    private(set) var dominantTrials = HandTrials()
    private(set) var nonDominantTrials = HandTrials()

    // MARK: - Daily High Score

    private(set) var dailyHighScore: Double = 0.0

    // MARK: - Configuration

    private let maxReadingsCount = 300 // ~30 seconds at 10Hz
    private let bufferTimeInterval: TimeInterval = 30.0
    private let forceThreshold: Double = 3.0 // lbs — below this, display 0

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private let bluetoothManager: BluetoothManager

    // MARK: - Computed Properties

    var displayForce: Double {
        let filtered = currentForce < forceThreshold ? 0.0 : currentForce
        switch selectedUnit {
        case .pounds:
            return filtered
        case .kilograms:
            return DataParser.poundsToKilograms(filtered)
        }
    }

    var displayPeakForce: Double {
        switch selectedUnit {
        case .pounds:
            return peakForce
        case .kilograms:
            return DataParser.poundsToKilograms(peakForce)
        }
    }

    var formattedForce: String {
        String(format: "%.1f", displayForce)
    }

    var formattedPeakForce: String {
        String(format: "%.1f", displayPeakForce)
    }

    var isConnected: Bool {
        bluetoothManager.connectionState.isConnected
    }

    var connectionState: ConnectionState {
        bluetoothManager.connectionState
    }

    var currentHandTrials: HandTrials {
        selectedHand == .dominant ? dominantTrials : nonDominantTrials
    }

    var canRecordTrial: Bool {
        !allTrialsComplete && peakForce > 0
    }

    var allTrialsComplete: Bool {
        dominantTrials.isFull && nonDominantTrials.isFull
    }

    var displayDailyHighScore: Double {
        switch selectedUnit {
        case .pounds: return dailyHighScore
        case .kilograms: return DataParser.poundsToKilograms(dailyHighScore)
        }
    }

    // MARK: - Initialization

    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
        loadDailyHighScore()
        setupSubscriptions()
    }

    // MARK: - Public Methods

    func resetPeak() {
        peakForce = 0.0
    }

    func clearReadings() {
        readings.removeAll()
        currentForce = 0.0
        peakForce = 0.0
    }

    func toggleUnit() {
        selectedUnit = selectedUnit == .pounds ? .kilograms : .pounds
    }

    // MARK: - Trial Methods

    func recordTrial() {
        guard peakForce > 0, !allTrialsComplete else { return }
        // Record to current hand
        switch selectedHand {
        case .dominant:
            dominantTrials.addTrial(peakForce: peakForce)
        case .nonDominant:
            nonDominantTrials.addTrial(peakForce: peakForce)
        }
        peakForce = 0.0

        // Auto-alternate: DOM → NON-DOM → DOM → NON-DOM → DOM → NON-DOM
        if !allTrialsComplete {
            selectedHand = selectedHand == .dominant ? .nonDominant : .dominant
            // If the next hand is already full, switch back
            if currentHandTrials.isFull {
                selectedHand = selectedHand == .dominant ? .nonDominant : .dominant
            }
        }
    }

    func resetAllTrials() {
        dominantTrials.reset()
        nonDominantTrials.reset()
        selectedHand = .dominant
    }

    // MARK: - Daily High Score Methods

    func resetDailyHighScore() {
        dailyHighScore = 0.0
        saveDailyHighScore()
    }

    // MARK: - Private Methods

    private func setupSubscriptions() {
        bluetoothManager.forceReadingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] force in
                self?.handleNewReading(force)
            }
            .store(in: &cancellables)
    }

    private func handleNewReading(_ force: Double) {
        currentForce = force

        let filtered = force < forceThreshold ? 0.0 : force

        // Update peak (only above threshold)
        if filtered > peakForce {
            peakForce = filtered
        }

        // Update daily high score
        if filtered > dailyHighScore {
            dailyHighScore = filtered
            saveDailyHighScore()
        }

        // Add to readings buffer (use filtered value so graph shows 0 below threshold)
        let reading = GripReading(timestamp: Date(), force: filtered)
        readings.append(reading)

        // Trim old readings
        trimReadings()
    }

    private func trimReadings() {
        // Remove readings older than buffer time interval
        let cutoffDate = Date().addingTimeInterval(-bufferTimeInterval)
        readings.removeAll { $0.timestamp < cutoffDate }

        // Also cap at max count
        if readings.count > maxReadingsCount {
            readings.removeFirst(readings.count - maxReadingsCount)
        }
    }

    // MARK: - Persistence

    private static let highScoreKey = "dailyHighScore"
    private static let highScoreDateKey = "dailyHighScoreDate"

    private func saveDailyHighScore() {
        UserDefaults.standard.set(dailyHighScore, forKey: Self.highScoreKey)
        UserDefaults.standard.set(Date(), forKey: Self.highScoreDateKey)
    }

    private func loadDailyHighScore() {
        // Check if the saved high score is from today
        if let savedDate = UserDefaults.standard.object(forKey: Self.highScoreDateKey) as? Date,
           Calendar.current.isDateInToday(savedDate) {
            dailyHighScore = UserDefaults.standard.double(forKey: Self.highScoreKey)
        } else {
            // Different day — reset
            dailyHighScore = 0.0
            UserDefaults.standard.removeObject(forKey: Self.highScoreKey)
            UserDefaults.standard.removeObject(forKey: Self.highScoreDateKey)
        }
    }
}
