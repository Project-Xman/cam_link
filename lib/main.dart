import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:photo_uploader/firebase_options.dart';
import 'package:photo_uploader/global_state.dart';
import 'package:photo_uploader/overlay.dart';
import 'package:photo_uploader/theme.dart';
import 'package:photo_uploader/util.dart';

import 'file_explorer_screen.dart';

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const ImageProcessingOverlay(),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "lib/.env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Get.put(GlobalState(), tag: 'global');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Uploader',
      theme: buildTheme(context),
      home: const FileExplorerScreen(),
    );
  }
}

ThemeData buildTheme(BuildContext context) {
  final brightness = View.of(context).platformDispatcher.platformBrightness;
  TextTheme textTheme = createTextTheme(context, "Roboto", "Roboto");
  MaterialTheme theme = MaterialTheme(textTheme);
  return brightness == Brightness.light ? theme.light() : theme.dark();
}
