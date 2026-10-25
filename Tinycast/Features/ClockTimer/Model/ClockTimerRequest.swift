import Foundation

/// A Clock duration, never a timer owned by Tinycast. Clock accepts less than 24 hours.
struct ClockTimerRequest: Equatable, Sendable {
    let seconds: Int

    static func recognizes(_ query: String) -> Bool {
        guard let first = query.split(whereSeparator: \.isWhitespace).first else { return false }
        return ["timer", "таймер"].contains(first.lowercased())
    }

    init?(query: String) {
        guard Self.recognizes(query) else { return nil }
        let parts = query.lowercased().split(whereSeparator: \.isWhitespace)
        let duration = parts.dropFirst().joined(separator: " ")
        guard !duration.isEmpty else { return nil }
        if duration.allSatisfy({ $0.isASCII && $0.isNumber }) {
            guard let minutes = Int(duration), (1...1439).contains(minutes) else { return nil }
            seconds = minutes * 60
            return
        }
        var number = ""
        var seen = Set<Int>()
        var total = 0
        for character in duration {
            if character.isWhitespace {
                guard number.isEmpty else { return nil }
                continue
            }
            if character.isASCII && character.isNumber {
                number.append(character)
                continue
            }
            let multiplier: Int
            switch character {
            case "h", "ч": multiplier = 3600
            case "m", "м": multiplier = 60
            case "s", "с": multiplier = 1
            default: return nil
            }
            guard let value = Int(number), value <= 86399 / multiplier,
                seen.insert(multiplier).inserted else { return nil }
            total += value * multiplier
            guard total <= 86399 else { return nil }
            number = ""
        }
        guard number.isEmpty, total > 0 else { return nil }
        seconds = total
    }

    var durationText: String {
        [(seconds / 3600, "h"), (seconds / 60 % 60, "min"), (seconds % 60, "s")]
            .filter { $0.0 > 0 }.map { "\($0.0) \($0.1)" }.joined(separator: " ")
    }
}
