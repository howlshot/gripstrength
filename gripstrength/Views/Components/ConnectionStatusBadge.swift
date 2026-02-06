//
//  ConnectionStatusBadge.swift
//  gripstrength
//
//  Compact connection status indicator
//

import SwiftUI

struct ConnectionStatusBadge: View {
    let state: ConnectionState

    private var statusColor: Color {
        switch state {
        case .connected:
            return Theme.success
        case .connecting, .scanning:
            return Theme.warning
        case .poweredOff:
            return Theme.error
        default:
            return Theme.textTertiary
        }
    }

    private var iconName: String {
        switch state {
        case .connected:
            return "checkmark.circle.fill"
        case .connecting:
            return "antenna.radiowaves.left.and.right"
        case .scanning:
            return "dot.radiowaves.left.and.right"
        case .poweredOff:
            return "bluetooth.slash"
        default:
            return "circle"
        }
    }

    var body: some View {
        HStack(spacing: Theme.spacingXS) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(statusColor)
                .symbolEffect(.pulse, isActive: state == .connecting || state == .scanning)

            Text(state.displayText)
                .font(Theme.captionFont)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, Theme.spacingSM)
        .padding(.vertical, Theme.spacingXS)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ConnectionStatusBadge(state: .connected)
        ConnectionStatusBadge(state: .connecting)
        ConnectionStatusBadge(state: .scanning)
        ConnectionStatusBadge(state: .disconnected)
        ConnectionStatusBadge(state: .poweredOff)
    }
    .padding()
    .background(Theme.background)
}
