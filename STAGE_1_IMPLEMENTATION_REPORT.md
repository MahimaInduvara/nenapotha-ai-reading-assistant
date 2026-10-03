# ReadBuddy AI — Stage 1 Security and Cleanup Report

Date: 21 August 2026  
Scope: Grade 1 and Grade 2 only  
Cost requirement: Zero paid services required

## Outcome

The Stage 1 source-code implementation is complete. The application now uses the free local response engine by default, contains no embedded Gemini credential, presents only the supported Grade 1–2 scope, avoids unsupported diagnosis and pronunciation claims, and passes Flutter static analysis and the current smoke test.

The Stage 1 release gate is still **pending** for two reasons:

1. The previously exposed Gemini key must be revoked or rotated by the project owner in Google AI Studio. Removing it from source code does not deactivate the old credential.
2. A fresh Android APK did not finish within two controlled ten-minute Gradle attempts. The existing APK is dated 9 August 2026 and must not be presented as evidence for these changes.

## Implemented changes and research reasons

| Change | Implementation | Research and engineering reason |
|---|---|---|
| Removed embedded AI secret | Cleared `env.json`; removed the fallback key from `GeminiService` | Prevents unauthorized use, unexpected cost, and an avoidable ethics/security weakness in the research artifact |
| Free local assistant is the default | `AIAssistantScreen` uses `AIService.generateChatResponse`; direct Gemini is optional only when explicitly configured | Keeps the application usable without payment, internet dependence, or a third-party data transfer |
| Safe optional Gemini path | Added `GeminiService.isConfigured`, missing-key validation, timeout/error fallback, and a deployment warning | Makes optional development use explicit while acknowledging that mobile build-time secrets are extractable |
| Grade 1–2 scope enforcement | Changed the assistant system prompt and active UI/test expectations to Grade 1 and Grade 2 | Aligns the application with the final binary classifier and prevents an unsupported Grade 3 contribution claim |
| Removed diagnostic language | Replaced “at-risk” with “additional-practice indicators” | The system does not perform a validated clinical or educational diagnosis; wording now matches the available evidence |
| Corrected pronunciation claim | Progress context now states that pronunciation is not measured and no accuracy claim is available | Speech recognition output is not equivalent to validated pronunciation accuracy |
| Corrected quiz description | Describes the quiz as grade-aware and rule-generated rather than AI-generated | Keeps the implementation claim faithful to the actual code |
| Safer progress status naming | Renamed internal risk status to practice status and uses `needs_practice`, `monitor`, and `on_track` | Avoids presenting a rule-based indicator as validated risk prediction |
| Analyzer cleanup | Fixed deprecated speech API usage, braces, final-field opportunity, unused import, and related lint findings | Produces a cleaner and more defensible implementation baseline |
| Real smoke test | Replaced the obsolete counter test with a language-selection and Grade 3 exclusion test | Tests behaviour that belongs to the actual application and its declared scope |
| Gradle resource limits | Reduced heap/metaspace limits and set two workers in `android/gradle.properties` | The former 8 GB heap plus 4 GB metaspace setting caused severe pressure on the development machine |

## Files changed

- `env.json`
- `android/gradle.properties`
- `lib/services/gemini_service.dart`
- `lib/services/ai_service.dart`
- `lib/screens/ai_assistant_screen.dart`
- `lib/screens/teacher_dashboard_screen.dart`
- `lib/screens/quiz_screen.dart`
- `lib/screens/reading_screen.dart`
- `lib/screens/letter_tracing_screen.dart`
- `lib/screens/profile/profile_tab_screen.dart`
- `test/widget_test.dart`

## Verification evidence

| Gate | Result | Evidence |
|---|---|---|
| Flutter static analysis | PASS | `flutter analyze` — “No issues found” |
| Flutter smoke test | PASS | `flutter test` — 1 test passed |
| Embedded Gemini key audit | PASS for active source/config | `env.json` contains an empty key and `gemini_service.dart` contains no fallback credential |
| Grade 1–2 active scope audit | PASS | Active assistant prompt and widget test enforce Grade 1–2; the test confirms that Grade 3 is absent |
| Unsupported claim audit | PASS for active UI | No active “at-risk,” AI-generated-comprehension, or pronunciation-accuracy claim remains |
| Fresh Android debug APK | PENDING | Gradle remained in its included-build work graph and timed out twice without an error or refreshed artifact |
| Revocation of previously exposed key | USER ACTION REQUIRED | Must be completed in Google AI Studio; it cannot be verified from this local workspace |

Historical thesis/source material may still mention Grade 3 when describing background, abandoned model iterations, exclusions, or earlier drafts. Those occurrences are not active application-support claims and should not be deleted indiscriminately.

## Required owner action

Open Google AI Studio, locate the formerly exposed Gemini API key, and revoke it or rotate it. Do not place the replacement key in Flutter source, `env.json`, screenshots, thesis appendices, or version control. For a public online AI feature, keep the secret in a protected backend. The application does not need that service for its default zero-cost local assistant.

## Android build follow-up

The old APK at `build/app/outputs/flutter-apk/app-debug.apk` is dated 9 August 2026. It is not valid Stage 1 evidence. The controlled builds on 21 August 2026 showed no Dart/compiler failure, but Gradle did not complete packaging within the ten-minute limit. The next diagnostic run should use Gradle `--info` or `--offline` mode to identify the included-build/dependency transform that is delaying completion.

## Stage 1 decision

- Source-code implementation: **COMPLETE**
- Static analysis and smoke test: **PASS**
- Fresh Android package: **PENDING**
- Exposed-key revocation: **USER ACTION REQUIRED**
- Overall Stage 1 release gate: **NOT YET CLOSED**

Stage 2 should begin only after the fresh APK is produced and the old Gemini credential is confirmed revoked. The planned Stage 2 focus is the Sinhala CNN numeric-label-to-Unicode mapping for the five supported letters, with unit tests and prediction evidence.