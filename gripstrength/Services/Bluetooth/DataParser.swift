//
//  DataParser.swift
//  gripstrength
//
//  Parses data from Jamar Smart Hand Dynamometer
//
//  Data Format: "::VAL 1,x.x"
//  - First value (1) is constant, ignore
//  - Second value (x.x) is force in pounds
//

import Foundation

enum DataParser {
    /// Parses Jamar Smart dynamometer data format
    /// Format: "::VAL 1,x.x" where x.x is the force value in pounds
    /// The raw BLE stream may contain multiple messages or partial messages.
    /// - Parameter string: Raw UTF-8 string from BLE characteristic
    /// - Returns: Most recent force value in pounds, or nil if parsing fails
    static func parseJamarData(_ string: String) -> Double? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to find "::VAL" anywhere in the string (handles buffered/concatenated data)
        guard let range = trimmed.range(of: "::VAL", options: .backwards) else {
            // Fallback: try to parse as a bare number (some firmware versions)
            return Double(trimmed)
        }

        // Extract everything after "::VAL"
        let afterPrefix = String(trimmed[range.upperBound...])
            .trimmingCharacters(in: .whitespaces)

        // Split by comma
        let components = afterPrefix.split(separator: ",")

        // If we have at least 2 parts: "1" and "x.x"
        if components.count >= 2 {
            let forceString = String(components[1])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: .controlCharacters)
            return Double(forceString)
        }

        // If only one component, it might be the force value itself
        if let single = components.first {
            let forceString = String(single)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: .controlCharacters)
            return Double(forceString)
        }

        return nil
    }

    /// Converts force from pounds to kilograms
    /// - Parameter pounds: Force value in pounds
    /// - Returns: Force value in kilograms
    static func poundsToKilograms(_ pounds: Double) -> Double {
        pounds * 0.453592
    }

    /// Converts force from kilograms to pounds
    /// - Parameter kilograms: Force value in kilograms
    /// - Returns: Force value in pounds
    static func kilogramsToPounds(_ kilograms: Double) -> Double {
        kilograms / 0.453592
    }
}
