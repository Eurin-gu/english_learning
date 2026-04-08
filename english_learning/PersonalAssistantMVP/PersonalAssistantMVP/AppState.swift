import Foundation
import SwiftData

@MainActor
final class AppState: ObservableObject {
    @Published var rawInputText: String = ""
    @Published var statusMessage: String = "准备就绪"

    let parser = ParserService()

    func importAndParseText(_ text: String, modelContext: ModelContext) {
        rawInputText = text

        let tasks = parser.parseTasks(from: text)
        for item in tasks {
            modelContext.insert(TaskItem(title: item.title, sourceText: text, dueDate: item.dueDate))
        }

        let expenses = parser.parseExpenses(from: text)
        for e in expenses {
            modelContext.insert(ExpenseItem(merchant: e.merchant, amount: e.amount, sourceText: text))
        }

        let words = parser.parseUnknownWords(from: text)
        for w in words {
            modelContext.insert(WordItem(word: w, sourceText: text))
        }

        do {
            try modelContext.save()
            statusMessage = "导入完成：任务\(tasks.count)条，支出\(expenses.count)条，生词\(words.count)个"
        } catch {
            statusMessage = "保存失败：\(error.localizedDescription)"
        }
    }
}
