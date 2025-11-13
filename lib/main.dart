import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g/utils/app_text.dart';
import 'controllers/app_controller.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize AppController
  Get.put(AppController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Girish Digital App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Neumorphism theme: Light grey background with light blue accents
        scaffoldBackgroundColor: const Color(0xFFE0E5EC),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF64B5F6), // Light blue
          secondary: const Color(0xFF42A5F5),
          tertiary: const Color(0xFF90CAF9),
          surface: const Color(0xFFE0E5EC),
          background: const Color(0xFFE0E5EC),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF2C3E50), // Dark blue-grey
          onBackground: const Color(0xFF2C3E50),
        ),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF2C3E50),
              displayColor: const Color(0xFF2C3E50),
            ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: const Color(0xFFE0E5EC),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: const Color(0xFF64B5F6),
            foregroundColor: Colors.white,
            textStyle: AppText.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFE0E5EC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 2),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// Widget to check authentication state on app start
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFE0E5EC),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
              ),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;

          // Load user data in the background
          Future.microtask(() async {
            await controller.loadUserData(user.uid);

            // Check if user has completed setup
            if (controller.pin.value.isNotEmpty &&
                controller.userName.value.isNotEmpty) {
              // Go to PIN login for security
              Get.offAll(
                () => const LoginPage(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 400),
              );
            } else {
              // User needs to complete setup, go to landing
              Get.offAll(
                () => const LandingPage(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 400),
              );
            }
          });

          // Show temporary loading screen
          return const Scaffold(
            backgroundColor: Color(0xFFE0E5EC),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
              ),
            ),
          );
        }

        // User is not logged in
        return const LandingPage();
      },
    );
  }
}
