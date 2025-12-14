import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_text.dart';

/// Unique cash-themed loading animation
class CashLoadingAnimation extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;

  const CashLoadingAnimation({
    super.key,
    this.message,
    this.size = 80,
    this.color,
  });

  @override
  State<CashLoadingAnimation> createState() => _CashLoadingAnimationState();
}

class _CashLoadingAnimationState extends State<CashLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Rotation animation
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Scale animation for coins
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating ring
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    children: List.generate(8, (index) {
                      final angle = (index * math.pi / 4);
                      return Positioned(
                        left: widget.size / 2 +
                            (widget.size / 2 - 8) * math.cos(angle) -
                            4,
                        top: widget.size / 2 +
                            (widget.size / 2 - 8) * math.sin(angle) -
                            4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Center animated coins stack
              AnimatedBuilder(
                animation: Listenable.merge([
                  _scaleController,
                  _pulseController,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (_scaleController.value * 0.2),
                    child: Opacity(
                      opacity: 0.7 + (_pulseController.value * 0.3),
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Bottom coin
                    Transform.translate(
                      offset: const Offset(-5, 8),
                      child: _buildCoin(
                        primaryColor.withOpacity(0.6),
                        widget.size * 0.35,
                      ),
                    ),
                    // Middle coin
                    Transform.translate(
                      offset: const Offset(0, 0),
                      child: _buildCoin(
                        primaryColor.withOpacity(0.8),
                        widget.size * 0.38,
                      ),
                    ),
                    // Top coin
                    Transform.translate(
                      offset: const Offset(5, -8),
                      child: _buildCoin(
                        primaryColor,
                        widget.size * 0.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Currency symbol in center
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: child,
                  );
                },
                child: Text(
                  '₱',
                  style: AppText.poppins(
                    fontSize: widget.size * 0.25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.7 + (_pulseController.value * 0.3),
                child: child,
              );
            },
            child: Text(
              widget.message!,
              style: AppText.poppins(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCoin(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.9),
            color,
          ],
          stops: const [0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

/// Compact inline version for buttons and small spaces
class CashLoadingInline extends StatefulWidget {
  final double size;
  final Color? color;

  const CashLoadingInline({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  State<CashLoadingInline> createState() => _CashLoadingInlineState();
}

class _CashLoadingInlineState extends State<CashLoadingInline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(3, (index) {
              final delay = index * 0.33;
              final animValue = (_controller.value - delay) % 1.0;
              final scale = animValue < 0.5
                  ? 0.5 + (animValue * 2) * 0.5
                  : 1.0 - ((animValue - 0.5) * 2) * 0.5;
              final opacity = animValue < 0.5
                  ? animValue * 2
                  : 1.0 - ((animValue - 0.5) * 2);

              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: widget.size * 0.6,
                    height: widget.size * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                    child: Center(
                      child: Text(
                        '₱',
                        style: AppText.poppins(
                          fontSize: widget.size * 0.35,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Simple spinning coin animation
class SpinningCoin extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;

  const SpinningCoin({
    super.key,
    this.size = 60,
    this.color,
    this.message,
  });

  @override
  State<SpinningCoin> createState() => _SpinningCoinState();
}

class _SpinningCoinState extends State<SpinningCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _rotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _rotation,
          builder: (context, child) {
            // Create 3D flip effect
            final angle = _rotation.value;
            final scale = (math.cos(angle) * 0.5 + 0.5).abs();

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: Transform.scale(
                scale: 0.7 + (scale * 0.3),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.8),
                        color,
                      ],
                      stops: const [0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '₱',
                      style: AppText.poppins(
                        fontSize: widget.size * 0.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: AppText.poppins(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
