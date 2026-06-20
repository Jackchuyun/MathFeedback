<div align="center">

# MathFeedback

### Local-first iOS feedback workspace for mathematics tutors

[English](./README.md) | [简体中文](./README.zh-CN.md)

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://www.swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![iOS](https://img.shields.io/badge/iOS-17%2B-black.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Local First](https://img.shields.io/badge/Data-local--first-0ea5e9.svg)](#privacy)
[![DeepSeek](https://img.shields.io/badge/AI-DeepSeek_optional-6366f1.svg)](#deepseek-teacher-comments)

[Features](#key-features) · [DeepSeek](#deepseek-teacher-comments) · [Getting Started](#getting-started) · [Privacy](#privacy) · [Contributing](#contributing)

</div>

MathFeedback is an iPhone app for high-school mathematics tutors and teachers who need a fast, structured way to write after-class feedback, track student progress, and export student reports.

The app is designed around a simple principle: classroom data should stay under the teacher's control. Student records, classes, feedback, ratings, and reports are stored locally with SwiftData by default. AI teacher comments are optional and only run when the user adds their own DeepSeek API key.

## Key Features

### Student and Class Management

- Organize students by grade and class.
- Keep notes and student profiles in one place.
- Filter the home dashboard by class for faster daily review.

### Structured Feedback Records

- Record lesson topics, learning content, homework, strengths, weaknesses, and teacher notes.
- Score each lesson with an overall rating plus skill dimensions.
- Track homework completion and class participation as learning indicators.

### Progress Insights

- View weekly feedback counts, average ratings, total students, and total feedback records.
- Highlight students who may need attention.
- Review recent activity, skill comparisons, trends, and repeated weak points.

### Reports and Data Portability

- Export student reports for sharing.
- Back up all local data to JSON.
- Restore and merge data from a previous backup when changing devices.

### iOS Native Interface

- Built with SwiftUI and SwiftData.
- Uses an iOS 26-inspired liquid glass visual style with compatibility fallbacks for earlier iOS versions.
- Focuses on a compact, teacher-friendly workflow rather than a marketing-style interface.

## DeepSeek Teacher Comments

MathFeedback can generate Chinese teacher comments from the current feedback form.

The generated comment uses:

- Student, grade, and class.
- Lesson topic and learning content.
- Overall rating.
- Skill dimensions such as concept understanding, calculation, reasoning, and written expression.
- Homework completion and class participation.
- Selected strengths and improvement tags.

AI generation is opt-in. The app only sends the current feedback inputs to DeepSeek after the user taps the generation button. The API key is stored in the iPhone Keychain and is not hardcoded in this repository.

## Getting Started

### Requirements

- Xcode 17 or newer
- iOS 17.0 or newer
- XcodeGen, if regenerating `MathFeedback.xcodeproj` from `project.yml`

### Clone

```sh
git clone https://github.com/Jackchuyun/MathFeedback.git
cd MathFeedback
```

### Generate the Xcode Project

```sh
xcodegen generate
```

### Build from the Command Line

```sh
xcodebuild -project MathFeedback.xcodeproj \
  -scheme MathFeedback \
  -sdk iphonesimulator \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
```

For a real device build, set your own Apple Developer Team in Xcode signing settings.

## Project Layout

```text
MathFeedbackApp.swift        App entry point
Models/                      SwiftData models for students, classes, feedback, and skill scores
Views/                       SwiftUI screens and reusable interface pieces
Utilities/                   Backup, export, DeepSeek, styling, and platform helpers
Assets.xcassets/             App icon and asset catalog
AppStore/                    App Store privacy, support, and review notes
project.yml                  XcodeGen project definition
```

## Privacy

MathFeedback is local-first. Student and feedback data are stored on the user's device with SwiftData by default.

The optional AI generation feature only runs after the user enters a DeepSeek API key in Settings and taps the AI generation button. When used, the app sends the current feedback inputs to DeepSeek to generate a teacher comment. The DeepSeek API key is stored in the device Keychain.

MathFeedback does not include third-party analytics, advertising, or tracking code.

## Contributing

Issues and pull requests are welcome. Useful contributions include:

- Bug fixes and iOS compatibility improvements.
- Better export templates and report formatting.
- Accessibility and localization improvements.
- Documentation, screenshots, and App Store preparation notes.

Please keep changes focused and include testing notes when opening a pull request.

## License

MathFeedback is released under the MIT License. See [LICENSE](./LICENSE).
