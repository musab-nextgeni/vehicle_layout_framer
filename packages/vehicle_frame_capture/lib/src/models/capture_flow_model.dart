import 'dart:io';

/// One shot in the guided vehicle capture flow, paired with the on-screen
/// label/instruction shown while that shot is active.
enum VehicleSide {
  front('Front', 'Align the front of the vehicle within the frame'),
  left('Left Side', 'Align the left side of the vehicle within the frame'),
  right('Right Side', 'Align the right side of the vehicle within the frame'),
  back('Back', 'Align the rear of the vehicle within the frame'),
  insideFrontRow(
    'Inside Front Row',
    'Capture the interior front row of the vehicle',
  ),
  insideBackRow(
    'Inside Back Row',
    'Capture the interior back row of the vehicle',
  ),
  engineBay(
    'Engine Bay',
    'Open the hood and align the engine bay within the frame',
  ),
  dashboardOdometer(
    'Dashboard & Odometer',
    'Capture the dashboard and odometer reading clearly',
  ),
  trunk('Trunk / Boot', 'Open the trunk and align it within the frame');

  /// Short title shown in the capture screen's header.
  final String label;

  /// One-line guidance shown under [label] while this step is active.
  final String instruction;
  const VehicleSide(this.label, this.instruction);
}

/// A single step of a [CaptureFlow]: which [VehicleSide] it's for, and the
/// captured [image] once the user has taken it (null until then).
class CaptureStep {
  final VehicleSide side;
  File? image;

  CaptureStep({required this.side, this.image});
}

/// Tracks progress through a vehicle capture sequence and stores the
/// captured image for each step.
///
/// Defaults to all 9 [VehicleSide] values in declaration order (4 exterior
/// angles, 2 interior rows, engine bay, dashboard/odometer, trunk). Pass
/// [sides] to capture a different subset or order — e.g. just the exterior
/// angles, or with a consumer-specific step appended.
class CaptureFlow {
  CaptureFlow({List<VehicleSide>? sides})
    : steps = (sides ?? VehicleSide.values)
          .map((side) => CaptureStep(side: side))
          .toList() {
    assert(steps.isNotEmpty, 'CaptureFlow requires at least one step');
  }

  final List<CaptureStep> steps;

  int currentStepIndex = 0;

  CaptureStep get currentStep => steps[currentStepIndex];

  bool get isComplete => steps.every((step) => step.image != null);

  void nextStep() {
    if (currentStepIndex < steps.length - 1) {
      currentStepIndex++;
    }
  }

  void updateImage(File image) {
    steps[currentStepIndex].image = image;
  }
}
