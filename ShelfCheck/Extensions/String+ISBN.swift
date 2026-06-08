import Foundation

extension String {
    func normalizeISBN() -> String {
        let cleaned = replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count == 10 {
            return convertISBN10to13(cleaned)
        }
        return cleaned
    }

    func isValidISBN() -> Bool {
        let cleaned = replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        return (cleaned.count == 13 || cleaned.count == 10) && cleaned.allSatisfy({ $0.isNumber || (cleaned.count == 10 && $0.lowercased() == "x") })
    }

    private func convertISBN10to13(_ isbn10: String) -> String {
        let prefix = "978" + String(isbn10.dropLast())
        let checksum = calculateISBN13Checksum(prefix)
        return prefix + String(checksum)
    }

    private func calculateISBN13Checksum(_ first12: String) -> Int {
        let digits = first12.compactMap { $0.wholeNumberValue }
        guard digits.count == 12 else { return 0 }
        let sum = digits.enumerated().reduce(0) { result, entry in
            let weight = entry.offset % 2 == 0 ? 1 : 3
            return result + entry.element * weight
        }
        return (10 - sum % 10) % 10
    }

    func normalizeTitle() -> String {
        lowercased()
            .replacingOccurrences(of: "(?i)\\d+(st|nd|rd|th)\\s*edition", with: "", options: .regularExpression)
            .components(separatedBy: ":").first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? lowercased()
    }

    func normalizeAuthor() -> String {
        lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: " ")
            .components(separatedBy: " ")
            .filter { !$0.isEmpty }
            .first ?? lowercased()
    }

    static func levenshtein(_ s1: String, _ s2: String) -> Int {
        let m = s1.count, n = s2.count
        guard m > 0, n > 0 else { return Swift.max(m, n) }
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }
        let s1Arr = Array(s1), s2Arr = Array(s2)
        for i in 1...m {
            for j in 1...n {
                let cost = s1Arr[i-1] == s2Arr[j-1] ? 0 : 1
                dp[i][j] = Swift.min(dp[i-1][j] + 1, dp[i][j-1] + 1, dp[i-1][j-1] + cost)
            }
        }
        return dp[m][n]
    }
}
