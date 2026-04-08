import SwiftUI
import SwiftData

@main
struct PersonalAssistantMVPApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    TaskItem.self,
                    ExpenseItem.self,
                    WordItem.self
                ])
        }
    }
}
