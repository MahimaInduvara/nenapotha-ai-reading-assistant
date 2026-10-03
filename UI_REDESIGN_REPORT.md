# ReadBuddy AI - App-wide UI Redesign

## Design goal

The interface is designed for Grade 1 and Grade 2 learners while remaining clear for parents and teachers. The redesign prioritises large touch targets, strong contrast, simple hierarchy, bilingual readability, predictable navigation, and a playful but academically appropriate visual identity.

## Shared visual system

- Brand colour: indigo
- Home accent: warm coral
- Learning accent: teal
- AI assistant accent: violet
- Progress accent: blue
- Profile and account controls: indigo
- Background: soft neutral grey with white elevated surfaces
- Standard corners: 12, 18, and 26 pixels
- Primary controls: at least 48 pixels high
- Material 3 components and transitions

## Implemented improvements

- Added a central `AppTheme` for typography, cards, forms, buttons, chips, dialogs, sheets, notifications, progress indicators, and transitions.
- Expanded `AppColors` into reusable semantic design tokens.
- Added a reusable ReadBuddy logo and softly decorated background.
- Rebuilt the splash screen with the ReadBuddy AI identity, bilingual message, animation, and Grade 1/2 scope.
- Rebuilt language selection with large accessible cards, visible selection state, a deliberate Continue action, and saved preference.
- Replaced the old bottom bar with a floating Material 3 navigation surface and clear selected-state pill.
- Fixed Sinhala bottom-navigation labels for the stored `sinhala` language code.
- Rebuilt the Learning Hub header and Grade 1/2 selector with a clear colour-coded segmented control.
- Unified login and reading controls with the indigo brand colour.
- Assigned distinct but consistent palettes to Home, AI Help, and Progress.
- Localised essential Home labels in Sinhala.
- Changed the Home hero story to match the student's selected grade instead of always showing a Grade 2 story.
- Preserved all existing AI, task scoring, tracing, Firebase, progress, quiz, reading, and recommendation logic.

## Verification

- `flutter analyze`: no issues.
- All existing tests and new UI interaction tests pass.
- UI tests verify bilingual selection, five-area navigation, Sinhala navigation labels, shared theme colours, and minimum control size.

## Remaining device verification

A Samsung SM A175F running Android 15 was detected. Live installation was attempted, but the local Gradle Android packaging process remained active without producing an APK in the verification window. This is a build-environment issue; Dart compilation, static analysis, and widget tests passed. A final phone screenshot review should be performed after the Android build cache completes successfully.
