import 'dart:io';

/// One shot in the guided vehicle capture flow, paired with the on-screen
/// label/instruction shown while that shot is active.
enum VehicleSide {
  front('Front', 'Align the front of the vehicle within the frame'),
  frontRight(
    'Front Right',
    'Align the front-right corner of the vehicle within the frame',
  ),
  frontSide('Front Side', 'Align the side of the vehicle within the frame'),
  rearLeft(
    'Rear Left',
    'Align the rear-left corner of the vehicle within the frame',
  ),
  roof('Roof', 'Align the roof of the vehicle within the frame'),
  console('Console', 'Capture the center console clearly'),
  dashboard('Dashboard', 'Capture the dashboard and odometer reading clearly'),
  cockPit('Cock Pit', 'Capture the driver cockpit/steering wheel area'),
  trunk('Trunk', 'Open the trunk and align it within the frame');

  /// Short title shown in the capture screen's header.
  final String label;

  /// One-line guidance shown under [label] while this step is active.
  final String instruction;
  const VehicleSide(this.label, this.instruction);

  /// The 6 exterior angles, in the order they're captured.
  ///
  /// [console], [roof], and [rearLeft] also appear in [interiorSides] — each
  /// category runs as its own independent [CaptureFlow], so the same side
  /// captured under both categories produces two separate images.
  static const List<VehicleSide> exteriorSides = [
    front,
    frontRight,
    frontSide,
    console,
    roof,
    rearLeft,
  ];

  /// The 6 interior angles, in the order they're captured. See
  /// [exteriorSides] for why some labels appear in both lists.
  static const List<VehicleSide> interiorSides = [
    dashboard,
    cockPit,
    trunk,
    console,
    roof,
    rearLeft,
  ];
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
/// Defaults to all 9 [VehicleSide] values in declaration order. Pass [sides]
/// to capture a different subset or order — e.g. [VehicleSide.exteriorSides]
/// or [VehicleSide.interiorSides] to run exterior/interior as separate
/// flows.
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
