import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'controllers/app_controller.dart';
import 'controllers/theme_controller.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'widgets/global_loading_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize AppController
  Get.put(AppController());
  Get.put(ThemeController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        title: 'Girish Digital App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeController.themeMode.value,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor:
                  1.0, // Force text scale to 1.0, ignoring device settings
            ),
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const GlobalLoadingOverlay(),
              ],
            ),
          );
        },
        home: const AuthWrapper(),
      ),
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
          return const _AuthLoadingScaffold();
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
          return const _AuthLoadingScaffold();
        }

        // User is not logged in
        return const LandingPage();
      },
    );
  }
}

class _AuthLoadingScaffold extends StatelessWidget {
  const _AuthLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      ),
    );
  }
}
