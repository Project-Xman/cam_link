import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:photo_uploader/firebase_options.dart';
import 'package:photo_uploader/app/bindings/initial_binding.dart';
import 'package:photo_uploader/app/core/theme/app_theme.dart';
import 'package:photo_uploader/app/core/values/app_strings.dart';
import 'package:photo_uploader/app/routes/app_routes.dart';
import 'package:photo_uploader/overlay.dart';

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const ImageProcessingOverlay(),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: "lib/.env");

  // Initialize services
  InitialBinding().dependencies();

  // Initialize Firebase only on supported platforms
  // Windows desktop doesn't support Firebase properly, so we skip it
  if (!kIsWeb && Platform.isWindows) {
    debugPrint('Skipping Firebase initialization on Windows desktop');
  } else {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      // Continue without Firebase - the app can still work with OAuth
    }
  }

  // Run the app
  runApp(const PhotoUploaderApp());
}

class PhotoUploaderApp extends StatelessWidget {
  const PhotoUploaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash, // Start with splash screen
      getPages: AppRoutes.pages,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      enableLog: true,
      logWriterCallback: (text, {bool? isError}) {
        // Custom logging can be added here
        debugPrint(text);
      },
    );
  }
}
