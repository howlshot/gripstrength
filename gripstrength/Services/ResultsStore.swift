//
//  ResultsStore.swift
//  gripstrength
//
//  Persistent storage for grip strength test results
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class ResultsStore {
    private(set) var records: [ResultRecord] = []

    private static let storageKey = "savedResults"

    init() {
        loadRecords()
    }

    // MARK: - Public Methods

    func saveResult(
        userName: String,
        dominantTrials: HandTrials,
        nonDominantTrials: HandTrials
    ) {
        let record = ResultRecord(
            userName: userName,
            dominantTrials: dominantTrials,
            nonDominantTrials: nonDominantTrials
        )
        records.insert(record, at: 0) // Most recent first
        persistRecords()
    }

    func deleteRecord(_ record: ResultRecord) {
        records.removeAll { $0.id == record.id }
        persistRecords()
    }

    func deleteRecords(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        persistRecords()
    }

    func clearAllRecords() {
        records.removeAll()
        persistRecords()
    }

    // MARK: - Private Methods

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            records = try decoder.decode([ResultRecord].self, from: data)
        } catch {
            print("Failed to decode saved results: \(error)")
        }
    }

    private func persistRecords() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(records)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            print("Failed to encode results: \(error)")
        }
    }
}
