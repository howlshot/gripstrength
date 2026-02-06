//
//  ResultsView.swift
//  gripstrength
//
//  Results summary showing dominant and non-dominant hand averages
//

import SwiftUI

struct ResultsView: View {
    @Bindable var viewModel: LiveReadingViewModel
    var resultsStore: ResultsStore

    @State private var showingSaveSheet = false
    @State private var userName = ""
    @State private var showingSavedConfirmation = false

    private var hasResults: Bool {
        viewModel.dominantTrials.count > 0 || viewModel.nonDominantTrials.count > 0
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

                        // Title
                        Text("Grip Strength Results")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)

                        // Results cards
                        VStack(spacing: Theme.spacingMD) {
                            ResultCard(
                                hand: .dominant,
                                trials: viewModel.dominantTrials,
                                unit: viewModel.selectedUnit
                            )

                            ResultCard(
                                hand: .nonDominant,
                                trials: viewModel.nonDominantTrials,
                                unit: viewModel.selectedUnit
                            )
                        }
                        .padding(.horizontal, Theme.spacingMD)

                        // Date
                        Text(Date(), format: .dateTime.month(.wide).day().year())
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textTertiary)

                        // Save button
                        if hasResults {
                            Button {
                                showingSaveSheet = true
                            } label: {
                                HStack(spacing: Theme.spacingSM) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Save Results")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundStyle(Theme.background)
                                .padding(.horizontal, Theme.spacingXL)
                                .padding(.vertical, Theme.spacingMD)
                                .background(Theme.gold)
                                .cornerRadius(Theme.cornerRadiusMD)
                            }
                            .padding(.top, Theme.spacingSM)
                        }

                        Spacer(minLength: Theme.spacingXL)
                    }
                }

                // Saved confirmation overlay
                if showingSavedConfirmation {
                    VStack {
                        Spacer()
                        HStack(spacing: Theme.spacingSM) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.success)
                            Text("Results saved")
                                .font(Theme.bodyFont)
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .padding(Theme.spacingMD)
                        .background(Theme.cardBackground)
                        .cornerRadius(Theme.cornerRadiusMD)
                        .padding(.bottom, Theme.spacingXL)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingSaveSheet) {
                SaveResultSheet(
                    userName: $userName,
                    onSave: saveResult,
                    onCancel: { showingSaveSheet = false }
                )
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func saveResult() {
        resultsStore.saveResult(
            userName: userName.isEmpty ? "Guest" : userName,
            dominantTrials: viewModel.dominantTrials,
            nonDominantTrials: viewModel.nonDominantTrials
        )
        showingSaveSheet = false
        userName = ""

        // Show confirmation
        withAnimation {
            showingSavedConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingSavedConfirmation = false
            }
        }
    }
}

// MARK: - Save Result Sheet

private struct SaveResultSheet: View {
    @Binding var userName: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.spacingLG) {
                    Text("Enter your name to save results")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textSecondary)

                    TextField("Name", text: $userName)
                        .font(Theme.bodyFont)
                        .padding(Theme.spacingMD)
                        .background(Theme.cardBackground)
                        .cornerRadius(Theme.cornerRadiusMD)
                        .foregroundStyle(Theme.textPrimary)

                    Button(action: onSave) {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacingMD)
                            .background(Theme.gold)
                            .cornerRadius(Theme.cornerRadiusMD)
                    }
                }
                .padding(Theme.spacingLG)
            }
            .navigationTitle("Save Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(Theme.gold)
                }
            }
        }
    }
}

// MARK: - Result Card

private struct ResultCard: View {
    let hand: Hand
    let trials: HandTrials
    let unit: ForceUnit

    private var displayAverage: Double? {
        guard let avg = trials.average else { return nil }
        return unit == .pounds ? avg : DataParser.poundsToKilograms(avg)
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
            if let avg = displayAverage {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", avg))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.gold)

                    Text(unit.abbreviation)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            } else {
                Text("—")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary.opacity(0.4))
            }

            // Individual trials
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    VStack(spacing: 2) {
                        Text("Trial \(index + 1)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)

                        if index < trials.count {
                            let force = trials.trials[index].peakForce
                            let displayValue = unit == .pounds
                                ? force
                                : DataParser.poundsToKilograms(force)
                            Text(String(format: "%.1f", displayValue))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                        } else {
                            Text("—")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.textTertiary.opacity(0.4))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Theme.spacingLG)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadiusLG)
    }
}

#Preview {
    ResultsView(
        viewModel: LiveReadingViewModel(bluetoothManager: BluetoothManager()),
        resultsStore: ResultsStore()
    )
    .preferredColorScheme(.dark)
}
