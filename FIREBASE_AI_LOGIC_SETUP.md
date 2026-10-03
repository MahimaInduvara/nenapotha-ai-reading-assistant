# ReadBuddy Firebase AI Logic setup (Spark plan)

The Flutter code is already configured for Firebase project
`reading-app-10118` and Android application
`com.example.reading_assistant_app`. Complete the following one-time console
setup before testing an open-ended chatbot question.

## 1. Enable Firebase AI Logic

1. Open <https://console.firebase.google.com/project/reading-app-10118>.
2. In the left menu, open **Build > Firebase AI Logic**.
3. Select **Get started**.
4. Choose **Gemini Developer API** as the provider. Do not choose the Vertex AI
   provider for this Spark-plan setup.
5. Continue through the guided workflow and enable the requested APIs.
6. Keep the project on **Spark**. Do not link a billing account and do not add a
   Gemini API key to this repository, Flutter source, Gradle files, or APK.

The app uses `FirebaseAI.googleAI()` and model `gemini-3.7-flash`. Firebase AI
Logic proxies the request and manages the Gemini Developer API credentials for
the app.

## 2. Register Android App Check

1. In the same Firebase project, open **Build > App Check**.
2. Select the Android app with package name
   `com.example.reading_assistant_app`.
3. Register **Play Integrity** as the production provider.
4. If Firebase asks for signing fingerprints, add the release certificate's
   SHA-256 fingerprint in **Project settings > Your apps > Android app**.

The Flutter app automatically uses:

- `AndroidProvider.debug` for debug builds and the emulator.
- `AndroidProvider.playIntegrity` for release builds.
- the App Check instance explicitly passed to Firebase AI Logic.

## 3. Register the emulator debug token

Debug tokens bypass normal device attestation and must be kept private.

1. Start the app on the emulator:

   ```powershell
   flutter run -d emulator-5554
   ```

2. Find the App Check debug token in the Flutter/Android log. If needed, run:

   ```powershell
   & "C:\Users\DELL\AppData\Local\Android\Sdk\platform-tools\adb.exe" `
     -s emulator-5554 logcat | Select-String "DebugAppCheckProvider"
   ```

   If your Android SDK is installed elsewhere, use its
   `platform-tools\adb.exe` path.

3. Copy only the token value.
4. In **Firebase Console > Build > App Check > Apps**, open the three-dot menu
   for the Android app and select **Manage debug tokens**.
5. Add a token named `ReadBuddy Android emulator` and paste the value.
6. Never commit the token or place it in Dart source.

## 4. Enforce App Check for Firebase AI Logic

1. First confirm that the registered debug build can answer one open-ended
   question.
2. Open **Firebase Console > Build > App Check > APIs**.
3. Select **Firebase AI Logic**.
4. Turn on **Enforcement**.

After enforcement, requests without a valid App Check token are rejected. The
app catches timeout and service errors and shows a friendly fallback while all
local exercises continue to work.

## 5. Verify the hybrid chatbot

Run both of these in the AI Help screen:

1. Local route: `Give me a Grade 1 letter selection exercise`
   - Expected: an interactive question with three answer choices.
   - Expected network use: none.
2. Firebase AI Logic route: `Why do stories have a moral?`
   - Expected: a short Grade 1/2 conversational explanation.
   - Expected network use: Firebase AI Logic only.

Sinhala examples:

- Local: `1 ශ්‍රේණියට අකුරු තෝරන අභ්‍යාසයක් දෙන්න`
- Firebase AI Logic: `කතාවක ආදර්ශයක් තිබෙන්නේ ඇයි?`

## Architecture boundary

- The local intent router selects known commands and creates Grade 1/2
  exercises.
- Firebase AI Logic answers only unmatched conversational questions.
- The CNN remains limited to Sinhala handwritten-letter recognition.
- The text classifier remains limited to Grade 1/2 text-difficulty
  classification.
- No student name, stored progress, handwriting image, or model output is sent
  by the Firebase AI conversational service.
