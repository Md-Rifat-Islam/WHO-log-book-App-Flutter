import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemChrome
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app.dart';

Future<void> main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. ENHANCEMENT: Set System UI Overlay Style
  // This makes the Status Bar transparent and the navigation bar sleek.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Makes status bar blend with app
      statusBarIconBrightness: Brightness.dark, // Dark icons for light background
      systemNavigationBarColor: Colors.white, // Clean bottom nav
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 4. ENHANCEMENT: Force Portrait Mode for consistency (Optional but recommended for forms)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 5. Run the application
  runApp(const WhoLogApp());
}

// --- Credentials for Reference ---
// Email: operator1@test.com | spv@test.com | admin@test.com | p_op@test.com
// Password: 123456