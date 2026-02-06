//
//  HistoryView.swift
//  gripstrength
//
//  Browse and view saved grip strength test results
//

import SwiftUI

struct HistoryView: View {
    @Bindable var resultsStore: ResultsStore
    @State private var selectedRecord: ResultRecord?
    @State private var selectedUnit: ForceUnit = .pounds

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if resultsStore.records.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(resultsStore.records) { record in
                            HistoryRow(record: record, unit: selectedUnit)
                                .listRowBackground(Theme.cardBackground)
                                .listRowSeparatorTint(Theme.textTertiary.opacity(0.3))
                                .onTapGesture {
                                    selectedRecord = record
                                }
                        }
                        .onDelete { offsets in
                            resultsStore.deleteRecords(at: offsets)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedUnit = selectedUnit == .pounds ? .kilograms : .pounds
                    } label: {
                        Text(selectedUnit.abbreviation)
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.gold)
                            .padding(.horizontal, Theme.spacingSM)
                            .padding(.vertical, Theme.spacingXS)
                            .background(Theme.cardBackground)
                            .cornerRadius(Theme.cornerRadiusSM)
                    }
                }
            }
            .sheet(item: $selectedRecord) { record in
                HistoryDetailView(record: record, unit: selectedUnit)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Empty History View

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: Theme.spacingLG) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.textTertiary)

            Text("No Saved Results")
                .font(Theme.titleFont)
                .foregroundStyle(Theme.textPrimary)

            Text("Save results from the Results tab\nto view them here")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - History Row

private struct HistoryRow: View {
    let record: ResultRecord
    let unit: ForceUnit

    private func displayValue(_ value: Double?) -> String {
        guard let value = value else { return "—" }
        let converted = unit == .pounds ? value : DataParser.poundsToKilograms(value)
        return String(format: "%.1f", converted)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack {
                Text(record.userName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Text(record.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textTertiary)
            }

            HStack(spacing: Theme.spacingLG) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DOM")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(displayValue(record.dominantAverage))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.gold)
                        Text(unit.abbreviation)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("NON-DOM")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(displayValue(record.nonDominantAverage))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.gold)
                        Text(unit.abbreviation)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.vertical, Theme.spacingSM)
    }
}

// MARK: - History Detail View

private struct HistoryDetailView: View {
    let record: ResultRecord
    let unit: ForceUnit

    @Environment(\.dismiss) private var dismiss

    private func displayValue(_ value: Double?) -> String {
        guard let value = value else { return "—" }
        let converted = unit == .pounds ? value : DataParser.poundsToKilograms(value)
        return String(format: "%.1f", converted)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingXL) {
                        // Canyon Ranch logo
                        Image("WhiteCanyonRanchLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .padding(.top, Theme.spacingLG)

                        // Name and date
                        VStack(spacing: Theme.spacingSM) {
                            Text(record.userName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)

                            Text(record.date, format: .dateTime.month(.wide).day().year())
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.textTertiary)
                        }

                        // Results cards
                        VStack(spacing: Theme.spacingMD) {
                            SavedResultCard(
                                hand: .dominant,
                                trial1: record.dominantTrial1,
                                trial2: record.dominantTrial2,
                                trial3: record.dominantTrial3,
                                average: record.dominantAverage,
                                unit: unit
                            )

                            SavedResultCard(
                                hand: .nonDominant,
                                trial1: record.nonDominantTrial1,
                                trial2: record.nonDominantTrial2,
                                trial3: record.nonDominantTrial3,
                                average: record.nonDominantAverage,
                                unit: unit
                            )
                        }
                        .padding(.horizontal, Theme.spacingMD)

                        Spacer(minLength: Theme.spacingXL)
                    }
                }
            }
            .navigationTitle("Result Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.gold)
                }
            }
        }
    }
}

// MARK: - Saved Result Card

private struct SavedResultCard: View {
    let hand: Hand
    let trial1: Double?
    let trial2: Double?
    let trial3: Double?
    let average: Double?
    let unit: ForceUnit

    private func displayValue(_ value: Double?) -> String {
        guard let value = value else { return "—" }
        let converted = unit == .pounds ? value : DataParser.poundsToKilograms(value)
        return String(format: "%.1f", converted)
    }

    var body: some View {
        VStack(spacing: Theme.spacingMD) {
            // Hand label
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.gold)

                Text(hand == .dominant ? "Dominant Hand" : "Non-Dominant Hand")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Spacer()
            }

            // Average value
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(displayValue(average))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(average != nil ? Theme.gold : Theme.textTertiary.opacity(0.4))

                if average != nil {
                    Text(unit.abbreviation)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            // Individual trials
            HStack(spacing: 0) {
                TrialColumn(label: "Trial 1", value: displayValue(trial1))
                TrialColumn(label: "Trial 2", value: displayValue(trial2))
                TrialColumn(label: "Trial 3", value: displayValue(trial3))
            }
        }
        .padding(Theme.spacingLG)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadiusLG)
    }
}

private struct TrialColumn: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textTertiary)

            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(value == "—" ? Theme.textTertiary.opacity(0.4) : Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HistoryView(resultsStore: ResultsStore())
        .preferredColorScheme(.dark)
}
