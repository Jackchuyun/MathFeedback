# Clear Sample Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clear all student-related records from the connected iPhone without removing preferences or Keychain credentials, and prevent debug builds from recreating sample data.

**Architecture:** First remove the permanent sample-seeding call. Then make a temporary debug-only cleanup build that explicitly deletes feedback, students, and classes, install and launch it, and finally remove the temporary cleanup code and install the clean final build. Keeping the bundle installed preserves its data container, preferences, and Keychain entries.

**Tech Stack:** SwiftUI, SwiftData, Xcode 26, `xcodebuild`, `xcrun devicectl`

---

### Task 1: Disable Automatic Sample Data

**Files:**
- Modify: `Views/ContentView.swift`

- [ ] **Step 1: Run the source guard and verify it fails**

Run:

```bash
if rg -n 'SampleDataSeeder\.seedIfNeeded' Views/ContentView.swift; then exit 1; fi
```

Expected: exit code `1`, with the current seeder call printed.

- [ ] **Step 2: Remove the seeder call**

Change the debug task to:

```swift
.task {
    #if DEBUG
    hasCompletedOnboarding = true
    #endif
}
```

- [ ] **Step 3: Re-run the source guard**

Run the Step 1 command again.

Expected: exit code `0` with no output.

### Task 2: Build and Run the One-Time Cleanup Version

**Files:**
- Temporarily modify: `Views/ContentView.swift`

- [ ] **Step 1: Back up the permanent source state**

```bash
cp Views/ContentView.swift /tmp/MathFeedback-ContentView-final.swift
```

- [ ] **Step 2: Add temporary debug-only cleanup logic**

Replace the debug task body with:

```swift
.task {
    #if DEBUG
    do {
        for feedback in try context.fetch(FetchDescriptor<Feedback>()) {
            context.delete(feedback)
        }
        for student in try context.fetch(FetchDescriptor<Student>()) {
            context.delete(student)
        }
        for classGroup in try context.fetch(FetchDescriptor<ClassGroup>()) {
            context.delete(classGroup)
        }
        try context.save()
        let students = try context.fetchCount(FetchDescriptor<Student>())
        let classes = try context.fetchCount(FetchDescriptor<ClassGroup>())
        let feedback = try context.fetchCount(FetchDescriptor<Feedback>())
        print("DATA_RESET_COMPLETE students=\(students) classes=\(classes) feedback=\(feedback)")
    } catch {
        print("DATA_RESET_FAILED \(error)")
    }
    hasCompletedOnboarding = true
    #endif
}
```

- [ ] **Step 3: Build the cleanup version**

```bash
xcodebuild -quiet -project MathFeedback.xcodeproj -scheme MathFeedback -configuration Debug -destination id=00008140-001A402036E8801C -derivedDataPath /tmp/MathFeedbackDerivedData -allowProvisioningUpdates -allowProvisioningDeviceRegistration DEVELOPMENT_TEAM=7274525WDK build
```

Expected: exit code `0`.

- [ ] **Step 4: Install on every reachable iPhone**

List reachable devices with `xcrun devicectl list devices`, then run for each `connected` or `available` iPhone:

```bash
xcrun devicectl device install app --device DEVICE_ID /tmp/MathFeedbackDerivedData/Build/Products/Debug-iphoneos/MathFeedback.app
```

Expected: `App installed` for each reachable iPhone.

- [ ] **Step 5: Launch the cleanup build and verify deletion**

```bash
xcrun devicectl device process launch --device DEVICE_ID --terminate-existing --console com.mathfeedback.app2
```

Expected console line:

```text
DATA_RESET_COMPLETE students=0 classes=0 feedback=0
```

### Task 3: Restore and Install the Final Version

**Files:**
- Restore: `Views/ContentView.swift`
- Modify: `project.yml`

- [ ] **Step 1: Restore the permanent source**

```bash
cp /tmp/MathFeedback-ContentView-final.swift Views/ContentView.swift
```

- [ ] **Step 2: Persist the active development team in project generation config**

Add under the target's base settings in `project.yml`:

```yaml
DEVELOPMENT_TEAM: 7274525WDK
```

- [ ] **Step 3: Verify no destructive or seeding logic remains**

```bash
if rg -n 'SampleDataSeeder\.seedIfNeeded|DATA_RESET_|context\.delete' Views/ContentView.swift; then exit 1; fi
```

Expected: exit code `0` with no output.

- [ ] **Step 4: Build and install the final version**

Run the Task 2 build command, list devices again, and install the resulting app on every reachable iPhone.

Expected: build exit code `0` and `App installed` for every reachable iPhone.

- [ ] **Step 5: Launch the final app**

```bash
xcrun devicectl device process launch --device DEVICE_ID --terminate-existing com.mathfeedback.app2
```

Expected: `Launched application with com.mathfeedback.app2 bundle identifier`.

- [ ] **Step 6: Verify and commit permanent changes**

```bash
git diff --check
git add Views/ContentView.swift project.yml
git commit -m "fix: stop seeding sample student data"
```

Expected: clean diff check and a commit containing only the permanent source/configuration changes.

