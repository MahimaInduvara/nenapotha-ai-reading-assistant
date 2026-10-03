import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/redesign/splash_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (error) {
    // Keep local learning features available if App Check cannot initialize.
    // Enforced Firebase AI Logic calls will then use the friendly error path.
    debugPrint('Firebase App Check activation failed: $error');
  }
  await StorageService().init();
  runApp(const ReadingAssistantApp());
}

class ReadingAssistantApp extends StatelessWidget {
  const ReadingAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NenaPotha AI',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,

      home: const SplashScreen(),
    );
  }
}
