import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';

class GlobalLoadingOverlay extends StatelessWidget {
  const GlobalLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = Get.find<AppController>();
    return Obx(() {
      final bool show = controller.isLoading.value;
      return IgnorePointer(
        ignoring: !show,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: show ? 1 : 0,
          child: Container(
            color: Colors.black.withOpacity(0.45),
            child: const Center(
              child: SizedBox.square(
                dimension: 72,
                child: CircularProgressIndicator(strokeWidth: 6),
              ),
            ),
          ),
        ),
      );
    });
  }
}
