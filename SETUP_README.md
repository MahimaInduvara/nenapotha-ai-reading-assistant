# ReadBuddy AI — Setup After Unzipping

This zip contains the Flutter app with the AI assistant already wired to call a
Firebase Cloud Function (`chatWithReadBuddy`), plus the Cloud Function code itself
in `functions/`. Nothing will actually connect until you complete these one-time
setup steps.

## What was changed in this update

- `lib/screens/ai_assistant_screen.dart`: replaced the old PHP/WAMP call with a
  Firebase Cloud Functions call (`_callFirebaseChatFunction`). Also fixed two
  places that were still using `GoogleFonts.poppins` for Sinhala text (the chat
  bubble text and the input field) — both now use `GoogleFonts.notoSansSinhala`.
- `pubspec.yaml`: added `firebase_core`, `cloud_functions`, `cloud_firestore`.
- `lib/main.dart`: added `Firebase.initializeApp()` before `runApp`.
- `lib/firebase_options.dart`: **placeholder file, see step 2 below.**
- `functions/index.js`: the Cloud Function — Firestore Q&A bank lookup first,
  Gemini API fallback second, logs unmatched questions.
- `functions/seed_qa_bank.js`: run once to populate starter Q&A entries.
- `firebase.json`, `firestore.rules`: project config, rules default to
  Admin-SDK-only access (safe default until you build an in-app admin screen).

## Setup steps (run in order)

### 1. Install the Firebase CLI and FlutterFire CLI (if you haven't already)
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

### 2. Replace the placeholder Firebase config — REQUIRED, app won't connect without this
```bash
flutterfire configure --project=reading_app
```
This overwrites `lib/firebase_options.dart` with your real project's API keys.
If you haven't created the `reading_app` Firebase project yet, this command
can create it for you interactively, or create it first at
https://console.firebase.google.com.

### 3. Install Flutter dependencies
```bash
flutter pub get
```

### 4. Install Cloud Function dependencies
```bash
cd functions
npm install
cd ..
```

### 5. Set your Gemini API key as a secret (not hardcoded anywhere)
```bash
firebase functions:secrets:set GEMINI_API_KEY
```
Paste your key when prompted.

### 6. Seed the Q&A bank (one-time)
```bash
cd functions
node seed_qa_bank.js
cd ..
```

### 7. Deploy the Cloud Function
```bash
firebase deploy --only functions
```

### 8. Run the app
```bash
flutter run -d chrome
```

## Known duplicate-file note

Your project has two copies of some screens (e.g. `lib/screens/ai_assistant_screen.dart`
and `lib/screens/ai/ai_assistant_screen.dart`). The one inside `lib/screens/ai/` is
just a one-line re-export (`export '../ai_assistant_screen.dart';`) pointing at the
real file — this is the one `navigation_config.dart` actually imports, and it's fine
as-is. The real, edited logic lives in `lib/screens/ai_assistant_screen.dart`, which
is the file this update changed. Similar re-export shims likely exist for
`home_screen.dart`, `progress_screen.dart`, etc. — worth cleaning up eventually so
there's only one copy of each screen, but not urgent.

## If something doesn't compile

Run `flutter clean && flutter pub get` first — this is the most common fix for
dependency-related compile errors after adding new packages.
