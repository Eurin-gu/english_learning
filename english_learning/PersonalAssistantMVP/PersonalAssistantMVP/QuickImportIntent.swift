import AppIntents
import SwiftData

struct QuickImportIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Import Text"
    static var description = IntentDescription("Import text into PersonalAssistantMVP and auto-parse tasks, expenses, and words.")

    @Parameter(title: "Input Text")
    var inputText: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let schema = Schema([TaskItem.self, ExpenseItem.self, WordItem.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: configuration)
        let context = ModelContext(container)

        let parser = ParserService()
        let tasks = parser.parseTasks(from: inputText)
        for item in tasks {
            context.insert(TaskItem(title: item.title, sourceText: inputText, dueDate: item.dueDate))
        }

        let expenses = parser.parseExpenses(from: inputText)
        for e in expenses {
            context.insert(ExpenseItem(merchant: e.merchant, amount: e.amount, sourceText: inputText))
        }

        let words = parser.parseUnknownWords(from: inputText)
        for w in words {
            context.insert(WordItem(word: w, sourceText: inputText))
        }

        try context.save()
        return .result(dialog: "导入完成：任务\(tasks.count)条，支出\(expenses.count)条，生词\(words.count)个。")
    }
}

struct PersonalAssistantShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickImportIntent(),
            phrases: [
                "Import text in \(.applicationName)",
                "Quick import with \(.applicationName)"
            ],
            shortTitle: "Quick Import Text",
            systemImageName: "square.and.arrow.down.on.square"
        )
    }
}
