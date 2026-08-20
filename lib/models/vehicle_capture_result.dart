import 'dart:io';

import 'package:vehicle_frame_capture/vehicle_frame_capture.dart';

/// The images captured for a completed exterior + interior capture session,
/// keyed by [VehicleSide] within each category so shared labels (Console,
/// Roof, Rear Left) are tracked independently per category.
class VehicleCaptureResult {
  final Map<VehicleSide, File?> exterior;
  final Map<VehicleSide, File?> interior;

  const VehicleCaptureResult({required this.exterior, required this.interior});
}
