import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _prefKey = 'theme_mode';

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;
  final RxBool isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_prefKey);
    if (storedValue == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else if (storedValue == 'light') {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.system;
    }
    isInitialized.value = true;
  }

  Future<void> toggleTheme() async {
    final nextMode =
        themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeMode.value = nextMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      nextMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
    _persistTheme(mode);
  }

  Future<void> _persistTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
              ? 'light'
              : 'system',
    );
  }
}
