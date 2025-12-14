import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app_text.dart';

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class NotificationService {
  /// Show a beautiful toast notification
  static void showNotification({
    required String title,
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.TOP,
    VoidCallback? onTap,
  }) {
    final colors = _getColorsForType(type);
    final icon = _getIconForType(type);

    Get.snackbar(
      title,
      message,
      backgroundColor: colors['background'],
      colorText: colors['text'],
      icon: Icon(
        icon,
        color: colors['text'],
        size: 24,
      ),
      snackPosition: position,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: duration,
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      boxShadows: [
        BoxShadow(
          color: colors['background']!.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      onTap: (_) => onTap?.call(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      titleText: Text(
        title,
        style: AppText.poppins(
          color: colors['text'],
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      messageText: Text(
        message,
        style: AppText.poppins(
          color: colors['text']!.withOpacity(0.9),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  /// Show success notification
  static void showSuccess(
    String message, {
    String title = 'Success',
    Duration duration = const Duration(seconds: 3),
  }) {
    showNotification(
      title: title,
      message: message,
      type: NotificationType.success,
      duration: duration,
    );
  }

  /// Show error notification
  static void showError(
    String message, {
    String title = 'Error',
    Duration duration = const Duration(seconds: 4),
  }) {
    showNotification(
      title: title,
      message: message,
      type: NotificationType.error,
      duration: duration,
    );
  }

  /// Show warning notification
  static void showWarning(
    String message, {
    String title = 'Warning',
    Duration duration = const Duration(seconds: 3),
  }) {
    showNotification(
      title: title,
      message: message,
      type: NotificationType.warning,
      duration: duration,
    );
  }

  /// Show info notification
  static void showInfo(
    String message, {
    String title = 'Info',
    Duration duration = const Duration(seconds: 3),
  }) {
    showNotification(
      title: title,
      message: message,
      type: NotificationType.info,
      duration: duration,
    );
  }

  static Map<String, Color> _getColorsForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return {
          'background': const Color(0xFF10B981),
          'text': Colors.white,
        };
      case NotificationType.error:
        return {
          'background': const Color(0xFFEF4444),
          'text': Colors.white,
        };
      case NotificationType.warning:
        return {
          'background': const Color(0xFFF59E0B),
          'text': Colors.white,
        };
      case NotificationType.info:
        return {
          'background': const Color(0xFF3B82F6),
          'text': Colors.white,
        };
    }
  }

  static IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
    }
  }
}

