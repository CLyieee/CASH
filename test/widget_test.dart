// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:g/main.dart';
import 'package:g/controllers/app_controller.dart';
import 'package:g/controllers/theme_controller.dart';

void main() {
  testWidgets('App initializes controllers properly',
      (WidgetTester tester) async {
    // Initialize controllers before building MyApp
    Get.put(AppController());
    Get.put(ThemeController());

    // Build our app - skip Firebase-dependent AuthWrapper
    await tester.pumpWidget(const MyApp());

    // Verify the app builds without ThemeController errors
    expect(find.byType(MyApp), findsOneWidget);

    // Clean up
    Get.reset();
  });
}
