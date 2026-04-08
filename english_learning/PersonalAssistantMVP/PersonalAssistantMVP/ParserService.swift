import Foundation

struct ParsedTask {
    let title: String
    let dueDate: Date?
}

struct ParsedExpense {
    let merchant: String
    let amount: Double
}

struct ParserService {
    private let taskKeywords = ["作业", "截止", "提交", "考试", "meeting", "deadline", "assignment", "quiz"]
    private let englishStopwords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "is", "are", "am", "i", "you", "he", "she", "it",
        "we", "they", "to", "of", "in", "on", "for", "at", "with", "as", "this", "that", "be",
        "was", "were", "do", "did", "done", "have", "has", "had", "from", "by", "not"
    ]

    func parseTasks(from text: String) -> [ParsedTask] {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.compactMap { line in
            let lower = line.lowercased()
            guard taskKeywords.contains(where: { lower.contains($0.lowercased()) }) else {
                return nil
            }
            return ParsedTask(title: line, dueDate: inferDate(from: line))
        }
    }

    func parseExpenses(from text: String) -> [ParsedExpense] {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map(String.init)

        return lines.compactMap { line in
            guard let amount = extractAmount(from: line) else { return nil }
            let merchant = inferMerchant(from: line)
            return ParsedExpense(merchant: merchant, amount: amount)
        }
    }

    func parseUnknownWords(from text: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: "\\b[A-Za-z]{4,20}\\b")
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        let words = regex?.matches(in: text, range: range).compactMap {
            ns.substring(with: $0.range).lowercased()
        } ?? []

        // Basic heuristic: keep unique, non-stopword tokens.
        return Array(Set(words.filter { !englishStopwords.contains($0) })).sorted()
    }

    private func inferDate(from line: String) -> Date? {
        let now = Date()
        let calendar = Calendar.current
        if line.contains("明天") || line.lowercased().contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        }
        if line.contains("今天") || line.lowercased().contains("today") {
            return now
        }
        return nil
    }

    private func extractAmount(from line: String) -> Double? {
        let pattern = "(¥|￥|rmb\\s*)?([0-9]+(?:\\.[0-9]{1,2})?)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let ns = line as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let first = regex.firstMatch(in: line, options: [], range: range), first.numberOfRanges >= 3 else {
            return nil
        }
        let number = ns.substring(with: first.range(at: 2))
        return Double(number)
    }

    private func inferMerchant(from line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "未知商家" }
        return String(trimmed.prefix(16))
    }
}
