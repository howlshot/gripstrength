//
//  ResultRecord.swift
//  gripstrength
//
//  Model for saved grip strength test results
//

import Foundation

struct ResultRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let userName: String

    // Dominant hand trials (stored in pounds)
    let dominantTrial1: Double?
    let dominantTrial2: Double?
    let dominantTrial3: Double?

    // Non-dominant hand trials (stored in pounds)
    let nonDominantTrial1: Double?
    let nonDominantTrial2: Double?
    let nonDominantTrial3: Double?

    // Computed properties
    var dominantAverage: Double? {
        let trials = [dominantTrial1, dominantTrial2, dominantTrial3].compactMap { $0 }
        guard !trials.isEmpty else { return nil }
        return trials.reduce(0, +) / Double(trials.count)
    }

    var nonDominantAverage: Double? {
        let trials = [nonDominantTrial1, nonDominantTrial2, nonDominantTrial3].compactMap { $0 }
        guard !trials.isEmpty else { return nil }
        return trials.reduce(0, +) / Double(trials.count)
    }

    var dominantTrialCount: Int {
        [dominantTrial1, dominantTrial2, dominantTrial3].compactMap { $0 }.count
    }

    var nonDominantTrialCount: Int {
        [nonDominantTrial1, nonDominantTrial2, nonDominantTrial3].compactMap { $0 }.count
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        userName: String,
        dominantTrials: HandTrials,
        nonDominantTrials: HandTrials
    ) {
        self.id = id
        self.date = date
        self.userName = userName

        self.dominantTrial1 = dominantTrials.trials.count > 0 ? dominantTrials.trials[0].peakForce : nil
        self.dominantTrial2 = dominantTrials.trials.count > 1 ? dominantTrials.trials[1].peakForce : nil
        self.dominantTrial3 = dominantTrials.trials.count > 2 ? dominantTrials.trials[2].peakForce : nil

        self.nonDominantTrial1 = nonDominantTrials.trials.count > 0 ? nonDominantTrials.trials[0].peakForce : nil
        self.nonDominantTrial2 = nonDominantTrials.trials.count > 1 ? nonDominantTrials.trials[1].peakForce : nil
        self.nonDominantTrial3 = nonDominantTrials.trials.count > 2 ? nonDominantTrials.trials[2].peakForce : nil
    }
}
