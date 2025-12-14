import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'cash_loading_animation.dart';

class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isVisible;
  final Color? backgroundColor;
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    this.message,
    required this.isVisible,
    this.backgroundColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: false,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1 : 0,
        child: Container(
          color: backgroundColor ?? Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CashLoadingAnimation(
                message: message ?? 'Loading...',
                color: indicatorColor,
                size: 90,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Global loading overlay that can be shown/hidden from anywhere
class GlobalLoadingOverlay extends StatelessWidget {
  final RxBool isLoading;
  final String? message;

  const GlobalLoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => LoadingOverlay(
          isVisible: isLoading.value,
          message: message,
        ));
  }
}
