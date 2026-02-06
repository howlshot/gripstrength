//
//  ForceGaugeView.swift
//  gripstrength
//
//  Large circular force display with animated ring indicator
//

import SwiftUI

struct ForceGaugeView: View {
    let currentForce: Double
    let peakForce: Double
    let unit: ForceUnit
    let maxForce: Double
    let onResetPeak: () -> Void
    let onToggleUnit: () -> Void

    @State private var animatedForce: Double = 0

    private var progress: Double {
        min(animatedForce / maxForce, 1.0)
    }

    private var formattedForce: String {
        String(format: "%.1f", currentForce)
    }

    private var formattedPeak: String {
        String(format: "%.1f", peakForce)
    }

    var body: some View {
        VStack(spacing: Theme.spacingSM) {
            // Main gauge
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        Theme.cardBackground,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Theme.goldDark, Theme.gold]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * progress)
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.15), value: progress)

                // Glow effect
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.gold.opacity(0.3),
                        style: StrokeStyle(lineWidth: 30, lineCap: .round)
                    )
                    .blur(radius: 10)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.15), value: progress)

                // Center content
                VStack(spacing: Theme.spacingXS) {
                    // Force value
                    Text(formattedForce)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.1), value: formattedForce)

                    // Unit button
                    Button(action: onToggleUnit) {
                        Text(unit.abbreviation)
                            .font(Theme.titleFont)
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
            .frame(width: 240, height: 240)
            .padding(.horizontal, Theme.spacingMD)
            .padding(.vertical, Theme.spacingSM)

            // Peak force section
            HStack(spacing: Theme.spacingMD) {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("PEAK")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textTertiary)

                    HStack(alignment: .firstTextBaseline, spacing: Theme.spacingXS) {
                        Text(formattedPeak)
                            .font(Theme.titleFont)
                            .foregroundStyle(Theme.gold)
                            .contentTransition(.numericText())

                        Text(unit.abbreviation)
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                Button(action: onResetPeak) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(Theme.spacingSM)
                        .background(
                            Circle()
                                .fill(Theme.elevatedBackground)
                        )
                }
            }
            .padding(.horizontal, Theme.spacingLG)
        }
        .onChange(of: currentForce) { _, newValue in
            withAnimation(.easeOut(duration: 0.15)) {
                animatedForce = newValue
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        ForceGaugeView(
            currentForce: 85.5,
            peakForce: 120.3,
            unit: .pounds,
            maxForce: 200,
            onResetPeak: {},
            onToggleUnit: {}
        )
    }
}
