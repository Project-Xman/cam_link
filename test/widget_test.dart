// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:photo_uploader/main.dart';

void main() {
  testWidgets('Photo Uploader app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PhotoUploaderApp());

    // Verify that our app loads properly
    expect(find.text('Photo Uploader'), findsWidgets);
    
    // Wait for the app to initialize
    await tester.pumpAndSettle();
    
    // The test passes if no exceptions are thrown
    expect(true, isTrue);
  });
}
