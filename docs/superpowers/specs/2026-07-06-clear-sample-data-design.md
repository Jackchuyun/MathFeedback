# Clear Sample Data Design

## Goal

Remove all students, class groups, feedback records, and skill scores from the currently connected iPhone while preserving app preferences and Keychain credentials. Prevent debug builds from recreating sample students.

## Approach

1. Remove the `SampleDataSeeder.seedIfNeeded` call from `ContentView` so future debug builds start with no sample records.
2. Add a temporary, debug-only one-time cleanup task that deletes all `Student` and `ClassGroup` models. Student cascade relationships remove associated `Feedback` and `SkillScore` records.
3. Build, install, and launch the cleanup version on every reachable iPhone.
4. Remove the temporary cleanup task, rebuild, and install the final version on every reachable iPhone.

## Data Boundaries

Deleted: students, class groups, feedback records, and skill scores.

Preserved: DeepSeek API Key in Keychain, DeepSeek model preference, onboarding preference, and other app settings.

## Verification

- Both cleanup and final builds succeed with the active Personal Team.
- The cleanup build launches successfully on the connected iPhone.
- The final source no longer calls `SampleDataSeeder`.
- The final build is installed on every reachable iPhone and launches successfully.

