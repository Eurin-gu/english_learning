import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \ExpenseItem.createdAt, order: .reverse) private var expenses: [ExpenseItem]
    @Query(sort: \WordItem.createdAt, order: .reverse) private var words: [WordItem]

    @StateObject private var state = AppState()
    @State private var photoItem: PhotosPickerItem?
    @State private var isOCRLoading = false
    @State private var selectedExpenseCategory: ExpenseCategory = .other

    private let ocrService = OCRService()

    var body: some View {
        NavigationStack {
            List {
                Section("导入") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("从截图/图片识别", systemImage: "photo")
                    }
                    .onChange(of: photoItem) { _, newValue in
                        guard let newValue else { return }
                        Task { await handlePhotoSelection(newValue) }
                    }

                    TextEditor(text: $state.rawInputText)
                        .frame(minHeight: 100)

                    Button {
                        state.importAndParseText(state.rawInputText, modelContext: modelContext)
                    } label: {
                        Label("解析当前文本", systemImage: "wand.and.stars")
                    }
                }

                Section("状态") {
                    if isOCRLoading {
                        ProgressView("OCR识别中...")
                    }
                    Text(state.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("任务 (\(tasks.count))") {
                    if tasks.isEmpty {
                        Text("暂无任务")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(tasks.prefix(10)) { task in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.title)
                                if let due = task.dueDate {
                                    Text("截止：\(due.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("支出 (\(expenses.count))") {
                    Picker("默认分类", selection: $selectedExpenseCategory) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .onChange(of: selectedExpenseCategory) { _, newValue in
                        applyCategoryToRecentExpenses(newValue)
                    }

                    if expenses.isEmpty {
                        Text("暂无支出记录")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(expenses.prefix(10)) { expense in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(expense.merchant)
                                    Text(expense.category.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("¥\(expense.amount, specifier: "%.2f")")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }

                Section("生词 (\(words.count))") {
                    if words.isEmpty {
                        Text("暂无生词")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(words.prefix(30)) { word in
                            HStack {
                                Text(word.word)
                                Spacer()
                                Button(word.isMastered ? "已掌握" : "不会") {
                                    word.isMastered.toggle()
                                    try? modelContext.save()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("个人效率管家 MVP")
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        isOCRLoading = true
        defer { isOCRLoading = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                state.statusMessage = "图片读取失败"
                return
            }
            let text = try await ocrService.recognizeText(from: image)
            state.importAndParseText(text, modelContext: modelContext)
        } catch {
            state.statusMessage = "OCR失败：\(error.localizedDescription)"
        }
    }

    private func applyCategoryToRecentExpenses(_ category: ExpenseCategory) {
        for expense in expenses.prefix(5) {
            if expense.category == .other {
                expense.category = category
            }
        }
        try? modelContext.save()
    }
}
