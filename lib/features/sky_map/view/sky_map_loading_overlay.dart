import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Full-screen cosmic loading overlay with an astronomy-themed animated reticle
/// and orbiting planet, eliminating startup flashes and providing smooth fade-out.
class SkyMapLoadingOverlay extends StatefulWidget {
  const SkyMapLoadingOverlay({
    required this.isReady,
    this.errorMessage,
    this.onRetry,
    this.isNightMode = false,
    this.accentColor,
    this.secondaryColor,
    this.backgroundColors,
    super.key,
  });

  final bool isReady;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isNightMode;
  final Color? accentColor;
  final Color? secondaryColor;
  final List<Color>? backgroundColors;

  @override
  State<SkyMapLoadingOverlay> createState() => _SkyMapLoadingOverlayState();
}

class _SkyMapLoadingOverlayState extends State<SkyMapLoadingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;
  bool _removedFromTree = false;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    if (widget.isReady) {
      _removedFromTree = true;
    }
  }

  @override
  void didUpdateWidget(covariant SkyMapLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isReady && widget.isReady) {
      // Begin fade out
    }
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_removedFromTree) {
      return const SizedBox.shrink();
    }

    final isNight = widget.isNightMode;
    final primaryColor = widget.accentColor ??
        (isNight ? const Color(0xFFFF5252) : const Color(0xFF00E5FF));
    final secondaryColor = widget.secondaryColor ??
        (isNight ? const Color(0xFFFF8888) : const Color(0xFF80D8FF));
    final rawBgColors = widget.backgroundColors ??
        (isNight
            ? const [Color(0xFF1E0505), Color(0xFF060913)]
            : const [Color(0xFF0F172A), Color(0xFF060913)]);
    final bgColors = rawBgColors.map((c) => c.withValues(alpha: 1.0)).toList();
    final hasError = widget.errorMessage != null && widget.errorMessage!.isNotEmpty;

    return IgnorePointer(
      ignoring: widget.isReady,
      child: AnimatedOpacity(
        opacity: widget.isReady ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        onEnd: () {
          if (widget.isReady && mounted) {
            setState(() => _removedFromTree = true);
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.1),
              radius: 1.2,
              colors: bgColors,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Celestial Loading Graphic
                  if (!hasError)
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ambient Pulsing Nebula Glow
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 0.85 + (_pulseController.value * 0.3);
                              final opacity = 0.2 + (_pulseController.value * 0.25);
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        primaryColor.withValues(alpha: opacity),
                                        primaryColor.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Outer Celestial Orbital Ring with Coordinate Ticks
                          RotationTransition(
                            turns: _orbitController,
                            child: CustomPaint(
                              size: const Size(120, 120),
                              painter: _CelestialRingPainter(
                                color: secondaryColor.withValues(alpha: 0.4),
                                accentColor: primaryColor,
                              ),
                            ),
                          ),

                          // Revolving Planet / Celestial Body
                          AnimatedBuilder(
                            animation: _orbitController,
                            builder: (context, child) {
                              final angle = _orbitController.value * 2 * math.pi;
                              const orbitRadius = 48.0;
                              final x = math.cos(angle) * orbitRadius;
                              final y = math.sin(angle) * orbitRadius;

                              return Transform.translate(
                                offset: Offset(x, y),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withValues(alpha: 0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Inner Telescope Crosshair Reticle & Glowing Core
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final coreScale = 0.92 + (_pulseController.value * 0.16);
                              return Transform.scale(
                                scale: coreScale,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size(48, 48),
                                      painter: _ReticleCrosshairPainter(
                                        color: primaryColor.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    Icon(
                                      Icons.stars_rounded,
                                      color: primaryColor,
                                      size: 28,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    // Error State Display
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Title Header
                  Text(
                    'MLASTRO SKY MAP',
                    style: TextStyle(
                      color: isNight ? const Color(0xFFFF8888) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle / Status indicator
                  if (!hasError)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 0.6 + (_pulseController.value * 0.4),
                          child: Text(
                            'Aligning stars & loading sky engine…',
                            style: TextStyle(
                              color: isNight ? const Color(0xFFFFCCCC) : Colors.white70,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            widget.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                          if (widget.onRetry != null) ...[
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: widget.onRetry,
                              child: const Text('Retry Loading'),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the rotating outer celestial coordinate ring.
class _CelestialRingPainter extends CustomPainter {
  const _CelestialRingPainter({
    required this.color,
    required this.accentColor,
  });

  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, circlePaint);

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;

    const numTicks = 24;
    for (var i = 0; i < numTicks; i++) {
      final angle = (i * 2 * math.pi) / numTicks;
      final isMajor = i % 6 == 0;
      final tickLength = isMajor ? 6.0 : 3.0;

      tickPaint.color = isMajor ? accentColor : color;

      final startX = center.dx + math.cos(angle) * (radius - tickLength);
      final startY = center.dy + math.sin(angle) * (radius - tickLength);
      final endX = center.dx + math.cos(angle) * radius;
      final endY = center.dy + math.sin(angle) * radius;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CelestialRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accentColor != accentColor;
}

/// Custom painter for the inner telescope reticle crosshairs.
class _ReticleCrosshairPainter extends CustomPainter {
  const _ReticleCrosshairPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const gap = 10.0;
    final extent = size.width / 2;

    // Top tick
    canvas.drawLine(Offset(center.dx, center.dy - gap), Offset(center.dx, center.dy - extent), paint);
    // Bottom tick
    canvas.drawLine(Offset(center.dx, center.dy + gap), Offset(center.dx, center.dy + extent), paint);
    // Left tick
    canvas.drawLine(Offset(center.dx - gap, center.dy), Offset(center.dx - extent, center.dy), paint);
    // Right tick
    canvas.drawLine(Offset(center.dx + gap, center.dy), Offset(center.dx + extent, center.dy), paint);
  }

  @override
  bool shouldRepaint(covariant _ReticleCrosshairPainter oldDelegate) =>
      oldDelegate.color != color;
}
