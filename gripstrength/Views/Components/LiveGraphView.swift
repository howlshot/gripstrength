//
//  LiveGraphView.swift
//  gripstrength
//
//  Real-time force chart using Swift Charts
//

import SwiftUI
import Charts

struct LiveGraphView: View {
    let readings: [GripReading]
    let unit: ForceUnit
    let maxForce: Double

    private var displayReadings: [(date: Date, force: Double)] {
        readings.map { reading in
            let force = unit == .pounds ? reading.force : reading.forceInKg
            return (date: reading.timestamp, force: force)
        }
    }

    private var maxDisplayForce: Double {
        unit == .pounds ? maxForce : DataParser.poundsToKilograms(maxForce)
    }

    private var timeRange: ClosedRange<Date> {
        let now = Date()
        let start = now.addingTimeInterval(-30)
        return start...now
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            // Header
            HStack {
                Text("FORCE OVER TIME")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textTertiary)

                Spacer()

                Text("30s")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textTertiary)
            }

            // Chart
            Chart {
                ForEach(displayReadings, id: \.date) { reading in
                    LineMark(
                        x: .value("Time", reading.date),
                        y: .value("Force", reading.force)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.gold, Theme.goldDark],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Time", reading.date),
                        y: .value("Force", reading.force)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.gold.opacity(0.3), Theme.gold.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXScale(domain: timeRange)
            .chartYScale(domain: 0...maxDisplayForce)
            .chartXAxis {
                AxisMarks(values: .stride(by: 10)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.textTertiary.opacity(0.3))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.textTertiary.opacity(0.3))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Theme.cardBackground.opacity(0.5))
                    .cornerRadius(Theme.cornerRadiusMD)
            }
            .frame(height: 140)
        }
        .padding(Theme.spacingSM)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadiusLG)
    }
}

#Preview {
    let sampleReadings: [GripReading] = {
        var readings: [GripReading] = []
        let now = Date()
        for i in 0..<100 {
            let time = now.addingTimeInterval(Double(-100 + i) * 0.3)
            let force = 50 + 30 * sin(Double(i) * 0.1) + Double.random(in: -5...5)
            readings.append(GripReading(timestamp: time, force: max(0, force)))
        }
        return readings
    }()

    ZStack {
        Theme.background.ignoresSafeArea()

        LiveGraphView(
            readings: sampleReadings,
            unit: .pounds,
            maxForce: 200
        )
        .padding()
    }
}
