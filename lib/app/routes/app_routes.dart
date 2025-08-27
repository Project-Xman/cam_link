import 'package:get/get.dart';
import '../modules/home/home_page.dart';
import '../modules/home/home_binding.dart';
import '../modules/file_explorer/file_explorer_page.dart';
import '../modules/file_explorer/file_explorer_binding.dart';
import '../modules/splash/splash_page.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/settings/settings_page.dart';
import '../modules/settings/settings_binding.dart';
import '../modules/auth/pages/login_page.dart';
import '../modules/auth/pages/signup_page.dart';
import '../modules/auth/pages/forgot_password_page.dart';
import '../modules/auth/pages/admin_approval_page.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/home/views/qr_code_form_page.dart';
import '../modules/home/qr_code_binding.dart';
import '../core/middleware/approval_middleware.dart';

/// App routes configuration
class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String fileExplorer = '/file-explorer';
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String forgotPassword = '/auth/forgot-password';
  static const String adminApproval = '/auth/admin-approval';
  static const String qrCodeForm = '/qr-code-form';
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
      middlewares: [ApprovalMiddleware()],
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
    // Authentication routes
    GetPage(
      name: login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: signup,
      page: () => const SignupPage(),
      binding: AuthBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordPage(),
      binding: AuthBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: adminApproval,
      page: () => const AdminApprovalPage(),
      binding: AuthBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: qrCodeForm,
      page: () => const QRCodeFormPage(),
      binding: QRCodeBinding(),
      transition: Transition.cupertino,
      middlewares: [ApprovalMiddleware()],
    ),
  ];

  /// Navigation methods
  static void toSplash() => Get.offAllNamed(splash);
  static void toHome() => Get.offAllNamed(home);
  static void toFileExplorer() => Get.toNamed(fileExplorer);
  static void toSettings() => Get.toNamed(settings);
  static void toLogin() => Get.offAllNamed(login);
  static void toSignup() => Get.toNamed(signup);
  static void toForgotPassword() => Get.toNamed(forgotPassword);
  static void toAdminApproval() => Get.offAllNamed(adminApproval);
  static void toQRCodeForm() => Get.toNamed(qrCodeForm);
  static void back() => Get.back();

  /// Check if current route matches
  static bool get isSplash => Get.currentRoute == splash;
  static bool get isHome => Get.currentRoute == home;
  static bool get isFileExplorer => Get.currentRoute == fileExplorer;
  static bool get isSettings => Get.currentRoute == settings;
  static bool get isLogin => Get.currentRoute == login;
  static bool get isSignup => Get.currentRoute == signup;
  static bool get isForgotPassword => Get.currentRoute == forgotPassword;
  static bool get isAdminApproval => Get.currentRoute == adminApproval;
  static bool get isQRCodeForm => Get.currentRoute == qrCodeForm;
}