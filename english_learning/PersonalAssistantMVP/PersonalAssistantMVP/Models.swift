import Foundation
import SwiftData

@Model
final class TaskItem {
    var title: String
    var sourceText: String
    var dueDate: Date?
    var createdAt: Date

    init(title: String, sourceText: String, dueDate: Date? = nil, createdAt: Date = .now) {
        self.title = title
        self.sourceText = sourceText
        self.dueDate = dueDate
        self.createdAt = createdAt
    }
}

enum ExpenseCategory: String, CaseIterable, Codable {
    case food = "餐饮"
    case transport = "交通"
    case study = "学习"
    case shopping = "购物"
    case entertainment = "娱乐"
    case other = "其他"
}

@Model
final class ExpenseItem {
    var merchant: String
    var amount: Double
    var categoryRaw: String
    var createdAt: Date
    var sourceText: String

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(merchant: String, amount: Double, category: ExpenseCategory = .other, createdAt: Date = .now, sourceText: String) {
        self.merchant = merchant
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.createdAt = createdAt
        self.sourceText = sourceText
    }
}

@Model
final class WordItem {
    var word: String
    var sourceText: String
    var isMastered: Bool
    var createdAt: Date

    init(word: String, sourceText: String, isMastered: Bool = false, createdAt: Date = .now) {
        self.word = word.lowercased()
        self.sourceText = sourceText
        self.isMastered = isMastered
        self.createdAt = createdAt
    }
}
