import 'package:flutter/material.dart';

/// Draws the rounded-rectangle capture guide used by [CameraScreen]: an
/// [idleColor] outline by default, turning to [readyColor] with a
/// translucent fill once [isReady] is true.
class VehicleFramePainter extends CustomPainter {
  /// Whether to render the "ready" state instead of the default idle
  /// outline.
  final bool isReady;

  /// Outline/fill color once [isReady] is true.
  final Color readyColor;

  /// Outline color while not yet ready.
  final Color idleColor;

  VehicleFramePainter({
    this.isReady = false,
    this.readyColor = Colors.greenAccent,
    this.idleColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final color = isReady ? readyColor : idleColor.withValues(alpha: 0.9);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Optimized for landscape (wider area, slightly taller relative to height)
    final rect = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.15,
      size.width * 0.7,
      size.height * 0.7,
    );

    // Draw main frame (The "Card")
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      paint,
    );

    // If ready, add a subtle green fill for visual feedback
    if (isReady) {
      final fillPaint = Paint()
        ..color = readyColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(20)),
        fillPaint,
      );

      // Optional: Add a subtle inner glow or thicker border when ready
      final glowPaint = Paint()
        ..color = readyColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(22)),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VehicleFramePainter oldDelegate) =>
      oldDelegate.isReady != isReady ||
      oldDelegate.readyColor != readyColor ||
      oldDelegate.idleColor != idleColor;
}
