import 'package:flutter/material.dart';

/// Visual customization for [CameraScreen] and [SummaryScreen].
///
/// Every field has a sensible default, and the text styles fall back to the
/// ambient [Theme] when left null — this package never forces a particular
/// font or color scheme on the consuming app.
class VehicleCaptureTheme {
  const VehicleCaptureTheme({
    this.readyColor = Colors.greenAccent,
    this.idleColor = Colors.white,
    this.dangerColor = Colors.redAccent,
    this.primaryColor = const Color(0xFF0D47A1),
    this.summaryBackgroundColor = const Color(0xFFF5F7FA),
    this.titleTextStyle,
    this.instructionTextStyle,
    this.labelTextStyle,
  });

  /// Frame outline, capture button border/fill, and level badge color once
  /// the device is level and ready to capture.
  final Color readyColor;

  /// Frame outline and capture button color while not yet ready.
  final Color idleColor;

  /// Level badge/horizon-line color while the device is not level.
  final Color dangerColor;

  /// Accent used for primary actions (e.g. the summary screen's Done button).
  final Color primaryColor;

  /// Background color of the optional [SummaryScreen].
  final Color summaryBackgroundColor;

  /// Style for the step header title (e.g. "Front"). Defaults to the
  /// ambient [Theme]'s `headlineSmall` when null.
  final TextStyle? titleTextStyle;

  /// Style for the step instruction line. Defaults to the ambient
  /// [Theme]'s `bodyMedium` when null.
  final TextStyle? instructionTextStyle;

  /// Style for small labels (level badge, step counter, summary captions).
  /// Defaults to the ambient [Theme]'s `labelLarge` when null.
  final TextStyle? labelTextStyle;
}
