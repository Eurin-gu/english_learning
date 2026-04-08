# PersonalAssistantMVP (iPhone Personal Use)

This is a first MVP code scaffold for your personal iPhone assistant app:

- OCR from screenshot/image (Vision)
- Parse tasks / expenses / English words from recognized text
- Save records locally (SwiftData)
- Provide a Shortcut action to import pasted/shared text quickly (App Intents)

## 1) How to run in Xcode

1. Open Xcode on your Mac.
2. Create a new iOS App project:
   - Product Name: `PersonalAssistantMVP`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Use SwiftData: `ON`
3. Replace files under the generated `PersonalAssistantMVP` target folder with files from this repo folder:
   - `PersonalAssistantMVPApp.swift`
   - `ContentView.swift`
   - `Models.swift`
   - `OCRService.swift`
   - `ParserService.swift`
   - `AppState.swift`
   - `QuickImportIntent.swift`
4. In target settings:
   - `Signing & Capabilities` -> add your personal Team.
   - `Info` -> add `NSPhotoLibraryUsageDescription`.
5. Build and run on iPhone.

## 2) What works in this MVP

- Import image from Photos, run OCR, then parse:
  - tasks (time/date/keywords based)
  - expenses (amount extraction + manual category)
  - unknown English words (basic stopword filtering)
- Manual text paste import and one-tap parse.
- Shortcut entry `Quick Import Text` for fast input.

## 3) Next improvements

- Add EventKit write to Reminders/Calendar.
- Better Chinese time parser (for "下周三晚上8点").
- Add dictionary API for word meaning.
- Add charts for monthly spending.
