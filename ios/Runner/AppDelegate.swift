import Flutter
import UIKit
import GoogleSignIn

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  GeneratedPluginRegistrant.register(with: self)
  GIDSignIn.sharedInstance.clientID = "424570474094-eph9e9id28fnjcoj2nta47alav7ve8nv.apps.googleusercontent.com"  // Replace with your client ID
  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
