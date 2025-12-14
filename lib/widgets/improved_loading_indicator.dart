import 'package:flutter/material.dart';
import '../utils/app_text.dart';
import 'cash_loading_animation.dart';

/// Beautiful loading indicator with optional message
class ImprovedLoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;

  const ImprovedLoadingIndicator({
    super.key,
    this.message,
    this.color,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return CashLoadingAnimation(
      message: message,
      color: color,
      size: size,
    );
  }
}

/// Inline loading indicator for buttons and small spaces
class InlineLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;

  const InlineLoadingIndicator({
    super.key,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CashLoadingInline(
      color: color,
      size: size,
    );
  }
}

/// Loading card with message - perfect for list items
class LoadingCard extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final Color? indicatorColor;

  const LoadingCard({
    super.key,
    required this.message,
    this.backgroundColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.cardColor;
    final indicatorColor = this.indicatorColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          CashLoadingInline(
            size: 28,
            color: indicatorColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: AppText.poppins(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
