import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import 'cash_loading_animation.dart';

class GlobalLoadingOverlay extends StatelessWidget {
  const GlobalLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = Get.find<AppController>();
    return Obx(() {
      final bool show = controller.isLoading.value;
      if (!show) return const SizedBox.shrink();

      return IgnorePointer(
        ignoring: false,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: show ? 1 : 0,
          child: Container(
            color: Colors.black.withOpacity(0.5),
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
                child: const CashLoadingAnimation(
                  message: 'Loading...',
                  size: 90,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
