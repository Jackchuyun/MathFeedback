# MathFeedback

MathFeedback is a local-first iOS app for high-school mathematics tutors and teachers. It helps create after-class feedback records, track student progress, export reports, and optionally generate teacher comments with DeepSeek.

## Features

- Manage students by grade and class.
- Record lesson topics, learning content, skill scores, strengths, improvement points, homework completion, and participation.
- Track trends with charts and skill comparisons.
- Export feedback and student reports.
- Back up and restore local data with JSON files.
- Optional DeepSeek-powered teacher comment generation.
- iOS 26-style liquid glass UI with compatibility fallback for earlier iOS versions.

## Privacy

MathFeedback is local-first. Student and feedback data are stored on the user's device with SwiftData by default.

The optional AI generation feature only runs after the user enters a DeepSeek API key in Settings and taps the AI generation button. When used, the app sends the current feedback inputs to DeepSeek to generate a teacher comment. The DeepSeek API key is stored in the device Keychain and is not hardcoded in this repository.

## Requirements

- Xcode 17 or newer
- iOS 17.0 or newer
- XcodeGen, if regenerating the Xcode project from `project.yml`

## Build

Generate the Xcode project:

```sh
xcodegen generate
```

Build from Xcode, or from the command line:

```sh
xcodebuild -project MathFeedback.xcodeproj \
  -scheme MathFeedback \
  -sdk iphonesimulator \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
```

For a real device build, set your own Apple Developer Team in Xcode signing settings.

## Open Source License

This project is released under the MIT License. See [LICENSE](LICENSE).
