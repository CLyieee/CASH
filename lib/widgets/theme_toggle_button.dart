import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController controller = Get.find<ThemeController>();
    return Obx(() {
      final isDark = controller.themeMode.value == ThemeMode.dark;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton.extended(
              heroTag: 'theme-toggle',
              backgroundColor: Theme.of(context).colorScheme.primary,
              label: Text(isDark ? 'Dark' : 'Light'),
              icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              onPressed: controller.toggleTheme,
            ),
          ),
        ),
      );
    });
  }
}
