// lib/screens/profile/profile_tab_screen.dart
// ProfileTabScreen is an alias for ProfileScreen.
export '../profile_screen.dart' show ProfileScreen;
import '../profile_screen.dart';

/// Thin alias so NavigationConfig can reference ProfileTabScreen
/// while the real implementation lives in profile_screen.dart.
typedef ProfileTabScreen = ProfileScreen;
