//
//  DashboardView.swift
//  gripstrength
//
//  Main dashboard showing force gauge and live graph
//

import SwiftUI

struct DashboardView: View {
    @Environment(BluetoothManager.self) private var bluetoothManager
    var viewModel: LiveReadingViewModel?
    @State private var showDebug = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if let viewModel = viewModel {
                    DashboardContent(viewModel: viewModel)
                } else {
                    ProgressView()
                        .tint(Theme.gold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let viewModel = viewModel, viewModel.isConnected {
                        HighScoreToolbarBadge(viewModel: viewModel)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Image("WhiteCanyonRanchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                        .opacity(0.85)
                }

                #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showDebug.toggle() }) {
                        Image(systemName: "ladybug")
                            .foregroundStyle(showDebug ? Theme.gold : Theme.textTertiary)
                    }
                }
                #endif
            }

        }
    }
}

// MARK: - High Score Toolbar Badge

private struct HighScoreToolbarBadge: View {
    @Bindable var viewModel: LiveReadingViewModel

    var body: some View {
        Button {
            viewModel.resetDailyHighScore()
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.gold)

                Text(String(format: "%.1f", viewModel.displayDailyHighScore))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.gold)

                Text(viewModel.selectedUnit.abbreviation)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }
}

private struct DashboardContent: View {
    @Bindable var viewModel: LiveReadingViewModel

    var body: some View {
        if viewModel.isConnected {
            VStack(spacing: Theme.spacingSM) {
                // Force gauge
                ForceGaugeView(
                    currentForce: viewModel.displayForce,
                    peakForce: viewModel.displayPeakForce,
                    unit: viewModel.selectedUnit,
                    maxForce: viewModel.selectedUnit == .pounds ? 200 : 91,
                    onResetPeak: { viewModel.resetPeak() },
                    onToggleUnit: { viewModel.toggleUnit() }
                )

                // Live graph (directly below gauge)
                LiveGraphView(
                    readings: viewModel.readings,
                    unit: viewModel.selectedUnit,
                    maxForce: 200
                )
                .padding(.horizontal, Theme.spacingMD)

                // Compact trial section
                CompactTrialSection(viewModel: viewModel)
                    .padding(.horizontal, Theme.spacingMD)

                Spacer(minLength: 0)
            }
        } else {
            ScrollView {
                DisconnectedStateView()
                    .padding(.vertical, Theme.spacingMD)
            }
        }
    }
}

// MARK: - Compact Trial Section

private struct CompactTrialSection: View {
    @Bindable var viewModel: LiveReadingViewModel

    var body: some View {
        VStack(spacing: Theme.spacingSM) {
            // Row 1: Current hand indicator + Record/Reset buttons
            HStack(spacing: Theme.spacingSM) {
                // Hand indicator (non-interactive, shows current hand)
                HStack(spacing: 0) {
                    ForEach(Hand.allCases, id: \.self) { hand in
                        Text(hand == .dominant ? "DOM" : "NON-DOM")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(
                                viewModel.selectedHand == hand
                                    ? Theme.background
                                    : Theme.textTertiary
                            )
                            .padding(.horizontal, Theme.spacingSM)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.selectedHand == hand
                                    ? Theme.gold
                                    : Color.clear
                            )
                    }
                }
                .background(Theme.elevatedBackground)
                .cornerRadius(6)

                Spacer()

                // Record button
                Button {
                    viewModel.recordTrial()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                        Text("Record")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Theme.background)
                    .padding(.horizontal, Theme.spacingSM)
                    .padding(.vertical, 6)
                    .background(Theme.gold)
                    .cornerRadius(6)
                }
                .disabled(!viewModel.canRecordTrial)
                .opacity(viewModel.canRecordTrial ? 1.0 : 0.4)

                // Reset button (resets all trials, restarts from dominant)
                Button {
                    viewModel.resetAllTrials()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, Theme.spacingSM)
                        .padding(.vertical, 6)
                        .background(Theme.elevatedBackground)
                        .cornerRadius(6)
                }
            }

            // Row 2: Both hands' trials in horizontal layout
            HStack(spacing: 0) {
                // Dominant trials
                TrialValuesGroup(
                    label: "DOM",
                    trials: viewModel.dominantTrials,
                    unit: viewModel.selectedUnit,
                    isActive: viewModel.selectedHand == .dominant
                )

                Rectangle()
                    .fill(Theme.textTertiary.opacity(0.3))
                    .frame(width: 1, height: 32)
                    .padding(.horizontal, 4)

                // Non-dominant trials
                TrialValuesGroup(
                    label: "N-DOM",
                    trials: viewModel.nonDominantTrials,
                    unit: viewModel.selectedUnit,
                    isActive: viewModel.selectedHand == .nonDominant
                )
            }
        }
        .padding(Theme.spacingSM)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadiusMD)
    }
}

private struct TrialValuesGroup: View {
    let label: String
    let trials: HandTrials
    let unit: ForceUnit
    let isActive: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                VStack(spacing: 1) {
                    if index == 0 {
                        Text(label)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isActive ? Theme.gold : Theme.textTertiary)
                    } else {
                        Text("T\(index + 1)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    if index < trials.count {
                        let force = trials.trials[index].peakForce
                        let displayValue = unit == .pounds
                            ? force
                            : DataParser.poundsToKilograms(force)
                        Text(String(format: "%.1f", displayValue))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.gold)
                    } else {
                        Text("—")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textTertiary.opacity(0.4))
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Average
            VStack(spacing: 1) {
                Text("AVG")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)

                if let avg = trials.average {
                    let displayAvg = unit == .pounds
                        ? avg
                        : DataParser.poundsToKilograms(avg)
                    Text(String(format: "%.1f", displayAvg))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                } else {
                    Text("—")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct DisconnectedStateView: View {
    var body: some View {
        VStack(spacing: Theme.spacingLG) {
            Spacer()

            // Logo
            Image("WhiteCanyonRanchLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 36)
                .opacity(0.9)

            // Icon
            ZStack {
                Circle()
                    .fill(Theme.cardBackground)
                    .frame(width: 120, height: 120)

                Image(systemName: "hand.raised")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Theme.textTertiary)
            }

            // Text
            VStack(spacing: Theme.spacingSM) {
                Text("No Device Connected")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.textPrimary)

                Text("Connect to your Jamar Smart\nHand Dynamometer to start measuring")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Instructions
            VStack(alignment: .leading, spacing: Theme.spacingMD) {
                InstructionRow(number: 1, text: "Turn on your Jamar Smart dynamometer")
                InstructionRow(number: 2, text: "Go to the Devices tab")
                InstructionRow(number: 3, text: "Tap Scan and select your device")
            }
            .padding(Theme.spacingLG)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadiusLG)
            .padding(.horizontal, Theme.spacingLG)

            Spacer()
        }
        .padding(.top, Theme.spacingXXL)
    }
}

private struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            ZStack {
                Circle()
                    .fill(Theme.gold.opacity(0.2))
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(Theme.labelFont)
                    .foregroundStyle(Theme.gold)
            }

            Text(text)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)

            Spacer()
        }
    }
}

private struct DebugBLEView: View {
    let rawData: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingXS) {
            Text("BLE DEBUG")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.warning)

            Text("Raw: \(rawData.isEmpty ? "(no data received)" : rawData.debugDescription)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.spacingSM)
        .background(Theme.elevatedBackground)
    }
}

#Preview("Connected") {
    let btManager = BluetoothManager()
    DashboardView(viewModel: LiveReadingViewModel(bluetoothManager: btManager))
        .environment(btManager)
        .preferredColorScheme(.dark)
}

#Preview("Disconnected") {
    ZStack {
        Theme.background.ignoresSafeArea()
        DisconnectedStateView()
    }
    .preferredColorScheme(.dark)
}
