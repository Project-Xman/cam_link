import 'package:get/get.dart';
import '../modules/home/home_page.dart';
import '../modules/home/home_binding.dart';
import '../modules/file_explorer/file_explorer_page.dart';
import '../modules/file_explorer/file_explorer_binding.dart';
import '../modules/splash/splash_page.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/settings/settings_page.dart';
import '../modules/settings/settings_binding.dart';
// import '../modules/auth/auth_page.dart';
// import '../modules/auth/auth_binding.dart';

/// App routes configuration
class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String fileExplorer = '/file-explorer';
  static const String auth = '/auth';
  static const String settings = '/settings';
  static const String about = '/about';

  /// Get pages configuration for GetX navigation
  static List<GetPage> get pages => [
    GetPage(
      name: splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: fileExplorer,
      page: () => const FileExplorerPage(),
      binding: FileExplorerBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
      transition: Transition.cupertino,
    ),
    // GetPage(
    //   name: auth,
    //   page: () => const AuthPage(),
    //   binding: AuthBinding(),
    //   transition: Transition.cupertino,
    // ),
  ];

  /// Navigation methods
  static void toSplash() => Get.offAllNamed(splash);
  static void toHome() => Get.offAllNamed(home);
  static void toFileExplorer() => Get.toNamed(fileExplorer);
  static void toSettings() => Get.toNamed(settings);
  static void toAuth() => Get.toNamed(auth);
  static void back() => Get.back();

  /// Check if current route matches
  static bool get isSplash => Get.currentRoute == splash;
  static bool get isHome => Get.currentRoute == home;
  static bool get isFileExplorer => Get.currentRoute == fileExplorer;
  static bool get isSettings => Get.currentRoute == settings;
  static bool get isAuth => Get.currentRoute == auth;
}