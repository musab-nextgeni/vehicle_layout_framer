import 'dart:io';
import 'package:flutter/foundation.dart' show UniqueKey;

/// Which section of the vehicle a [VehicleSide] belongs to, used to group
/// angles under "Exterior"/"Interior" tabs in the capture UI.
enum VehicleCaptureCategory {
  exterior('Exterior'),
  interior('Interior');

  /// Short title shown on the category's tab.
  final String label;
  const VehicleCaptureCategory(this.label);
}

/// A capture target: one photo the guided flow asks for, with the
/// label/instruction shown while it's active.
///
/// This is a plain class rather than an enum so consumers aren't limited to
/// a fixed set of angles — [VehicleSide.catalog] lists every angle this
/// package knows about (far more than any single flow should default to),
/// and [VehicleSide.custom] lets a consumer define one-off angles the
/// catalog doesn't cover.
class VehicleSide {
  const VehicleSide({
    required this.id,
    required this.category,
    required this.label,
    required this.instruction,
    this.requiresLevel = true,
  });

  /// Creates a one-off angle not in the built-in [catalog], e.g. one a user
  /// types in at runtime. [id] defaults to a fresh unique value so callers
  /// don't need to invent one.
  factory VehicleSide.custom({
    required String label,
    String instruction = '',
    VehicleCaptureCategory category = VehicleCaptureCategory.exterior,
    bool requiresLevel = true,
    String? id,
  }) =>
      VehicleSide(
        id: id ?? 'custom_${UniqueKey()}',
        category: category,
        label: label,
        instruction: instruction,
        requiresLevel: requiresLevel,
      );

  /// Stable identity used for equality/hashing (e.g. as a `Map` key) — two
  /// [VehicleSide]s with the same [id] are considered the same angle even
  /// if they're different Dart object instances.
  final String id;

  /// Which [VehicleCaptureCategory] tab this angle appears under.
  final VehicleCaptureCategory category;

  /// Short title shown in the capture screen's header and on tiles.
  final String label;

  /// One-line guidance shown under [label] while this step is active.
  final String instruction;

  /// Whether [CameraScreen] should require the device to be held level
  /// before allowing a shot for this angle.
  ///
  /// Defaults to true (most exterior/interior shots are taken holding the
  /// phone roughly upright). Angles that are inherently shot tilted up or
  /// down — [roof], [undercarriage], [engineBay], etc. — set this to false
  /// in the built-in catalog so the accelerometer-based level check doesn't
  /// permanently block their shutter.
  final bool requiresLevel;

  @override
  bool operator ==(Object other) => other is VehicleSide && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VehicleSide($id)';

  // ---------------------------------------------------------------------
  // Exterior — default set (the "front, back, sides" essentials).
  // ---------------------------------------------------------------------

  static const front = VehicleSide(
    id: 'front',
    category: VehicleCaptureCategory.exterior,
    label: 'Front',
    instruction: 'Align the front of the vehicle within the frame',
  );
  static const frontRight = VehicleSide(
    id: 'frontRight',
    category: VehicleCaptureCategory.exterior,
    label: 'Front Right',
    instruction: 'Align the front-right corner of the vehicle within the frame',
  );
  static const frontSide = VehicleSide(
    id: 'frontSide',
    category: VehicleCaptureCategory.exterior,
    label: 'Front Side',
    instruction: 'Align the front side of the vehicle within the frame',
  );
  static const rearRight = VehicleSide(
    id: 'rearRight',
    category: VehicleCaptureCategory.exterior,
    label: 'Rear Right',
    instruction: 'Align the rear-right corner of the vehicle within the frame',
  );
  static const rear = VehicleSide(
    id: 'rear',
    category: VehicleCaptureCategory.exterior,
    label: 'Rear',
    instruction: 'Align the rear of the vehicle within the frame',
  );
  static const rearLeft = VehicleSide(
    id: 'rearLeft',
    category: VehicleCaptureCategory.exterior,
    label: 'Rear Left',
    instruction: 'Align the rear-left corner of the vehicle within the frame',
  );

  // ---------------------------------------------------------------------
  // Exterior — extended catalog.
  // ---------------------------------------------------------------------

  static const driverSideProfile = VehicleSide(
    id: 'driverSideProfile',
    category: VehicleCaptureCategory.exterior,
    label: 'Driver Side',
    instruction: 'Capture the full driver-side profile of the vehicle',
  );
  static const passengerSideProfile = VehicleSide(
    id: 'passengerSideProfile',
    category: VehicleCaptureCategory.exterior,
    label: 'Passenger Side',
    instruction: 'Capture the full passenger-side profile of the vehicle',
  );
  static const wheelFrontLeft = VehicleSide(
    id: 'wheelFrontLeft',
    category: VehicleCaptureCategory.exterior,
    label: 'Front Left Wheel',
    instruction: 'Capture the front-left wheel and tire clearly',
    requiresLevel: false,
  );
  static const wheelFrontRight = VehicleSide(
    id: 'wheelFrontRight',
    category: VehicleCaptureCategory.exterior,
    label: 'Front Right Wheel',
    instruction: 'Capture the front-right wheel and tire clearly',
    requiresLevel: false,
  );
  static const wheelRearLeft = VehicleSide(
    id: 'wheelRearLeft',
    category: VehicleCaptureCategory.exterior,
    label: 'Rear Left Wheel',
    instruction: 'Capture the rear-left wheel and tire clearly',
    requiresLevel: false,
  );
  static const wheelRearRight = VehicleSide(
    id: 'wheelRearRight',
    category: VehicleCaptureCategory.exterior,
    label: 'Rear Right Wheel',
    instruction: 'Capture the rear-right wheel and tire clearly',
    requiresLevel: false,
  );
  static const windshield = VehicleSide(
    id: 'windshield',
    category: VehicleCaptureCategory.exterior,
    label: 'Windshield',
    instruction: 'Capture the windshield, checking for chips or cracks',
  );
  static const rearWindshield = VehicleSide(
    id: 'rearWindshield',
    category: VehicleCaptureCategory.exterior,
    label: 'Rear Windshield',
    instruction: 'Capture the rear windshield clearly',
  );
  static const headlights = VehicleSide(
    id: 'headlights',
    category: VehicleCaptureCategory.exterior,
    label: 'Headlights',
    instruction: 'Capture the headlights close up',
  );
  static const taillights = VehicleSide(
    id: 'taillights',
    category: VehicleCaptureCategory.exterior,
    label: 'Taillights',
    instruction: 'Capture the taillights close up',
  );
  static const grille = VehicleSide(
    id: 'grille',
    category: VehicleCaptureCategory.exterior,
    label: 'Grille',
    instruction: 'Capture the front grille close up',
  );
  static const licensePlate = VehicleSide(
    id: 'licensePlate',
    category: VehicleCaptureCategory.exterior,
    label: 'License Plate',
    instruction: 'Capture the license plate clearly',
    requiresLevel: false,
  );
  static const vinPlate = VehicleSide(
    id: 'vinPlate',
    category: VehicleCaptureCategory.exterior,
    label: 'VIN Plate',
    instruction: 'Capture the VIN plate or sticker clearly',
    requiresLevel: false,
  );
  static const exteriorRoof = VehicleSide(
    id: 'exteriorRoof',
    category: VehicleCaptureCategory.exterior,
    label: 'Roof',
    instruction: 'Capture the roof from above or a raised angle',
    requiresLevel: false,
  );
  static const undercarriage = VehicleSide(
    id: 'undercarriage',
    category: VehicleCaptureCategory.exterior,
    label: 'Undercarriage',
    instruction: 'Capture the undercarriage from underneath the vehicle',
    requiresLevel: false,
  );
  static const fuelDoor = VehicleSide(
    id: 'fuelDoor',
    category: VehicleCaptureCategory.exterior,
    label: 'Fuel Door',
    instruction: 'Open and capture the fuel door or charging port',
  );
  static const sideMirrors = VehicleSide(
    id: 'sideMirrors',
    category: VehicleCaptureCategory.exterior,
    label: 'Side Mirrors',
    instruction: 'Capture the side mirrors clearly',
  );
  static const exhaustPipe = VehicleSide(
    id: 'exhaustPipe',
    category: VehicleCaptureCategory.exterior,
    label: 'Exhaust Pipe',
    instruction: 'Capture the exhaust pipe(s) clearly',
    requiresLevel: false,
  );
  static const sunroofExterior = VehicleSide(
    id: 'sunroofExterior',
    category: VehicleCaptureCategory.exterior,
    label: 'Sunroof (Exterior)',
    instruction: 'Capture the sunroof/moonroof from outside',
    requiresLevel: false,
  );
  static const engineBay = VehicleSide(
    id: 'engineBay',
    category: VehicleCaptureCategory.exterior,
    label: 'Engine Bay',
    instruction: 'Open the hood and align the engine bay within the frame',
    requiresLevel: false,
  );

  // ---------------------------------------------------------------------
  // Interior — default set.
  // ---------------------------------------------------------------------

  static const dashboard = VehicleSide(
    id: 'dashboard',
    category: VehicleCaptureCategory.interior,
    label: 'Dashboard',
    instruction: 'Capture the dashboard clearly',
  );
  static const cockpit = VehicleSide(
    id: 'cockpit',
    category: VehicleCaptureCategory.interior,
    label: 'Cock Pit',
    instruction: 'Capture the front seats and cockpit area',
  );
  static const trunk = VehicleSide(
    id: 'trunk',
    category: VehicleCaptureCategory.interior,
    label: 'Trunk',
    instruction: 'Open the trunk and align it within the frame',
  );
  static const console = VehicleSide(
    id: 'console',
    category: VehicleCaptureCategory.interior,
    label: 'Console',
    instruction: 'Capture the center console clearly',
  );
  static const roof = VehicleSide(
    id: 'roof',
    category: VehicleCaptureCategory.interior,
    label: 'Roof',
    instruction: 'Capture the interior roof/headliner area',
    requiresLevel: false,
  );
  static const driverDoor = VehicleSide(
    id: 'driverDoor',
    category: VehicleCaptureCategory.interior,
    label: 'Driver Door',
    instruction: 'Capture the interior of the driver door',
  );

  // ---------------------------------------------------------------------
  // Interior — extended catalog.
  // ---------------------------------------------------------------------

  static const instrumentCluster = VehicleSide(
    id: 'instrumentCluster',
    category: VehicleCaptureCategory.interior,
    label: 'Instrument Cluster',
    instruction: 'Capture the instrument cluster and odometer reading clearly',
  );
  static const frontSeats = VehicleSide(
    id: 'frontSeats',
    category: VehicleCaptureCategory.interior,
    label: 'Front Seats',
    instruction: 'Capture the front seats clearly',
  );
  static const rearSeats = VehicleSide(
    id: 'rearSeats',
    category: VehicleCaptureCategory.interior,
    label: 'Rear Seats',
    instruction: 'Capture the rear seats clearly',
  );
  static const passengerDoor = VehicleSide(
    id: 'passengerDoor',
    category: VehicleCaptureCategory.interior,
    label: 'Passenger Door',
    instruction: 'Capture the interior of the passenger door',
  );
  static const rearDoor = VehicleSide(
    id: 'rearDoor',
    category: VehicleCaptureCategory.interior,
    label: 'Rear Door',
    instruction: 'Capture the interior of a rear door',
  );
  static const headliner = VehicleSide(
    id: 'headliner',
    category: VehicleCaptureCategory.interior,
    label: 'Headliner',
    instruction: 'Capture the headliner clearly',
    requiresLevel: false,
  );
  static const sunroofInterior = VehicleSide(
    id: 'sunroofInterior',
    category: VehicleCaptureCategory.interior,
    label: 'Sunroof (Interior)',
    instruction: 'Capture the sunroof/moonroof from inside',
    requiresLevel: false,
  );
  static const steeringWheel = VehicleSide(
    id: 'steeringWheel',
    category: VehicleCaptureCategory.interior,
    label: 'Steering Wheel',
    instruction: 'Capture the steering wheel clearly',
  );
  static const infotainmentScreen = VehicleSide(
    id: 'infotainmentScreen',
    category: VehicleCaptureCategory.interior,
    label: 'Infotainment Screen',
    instruction: 'Capture the infotainment screen clearly',
  );
  static const gloveBox = VehicleSide(
    id: 'gloveBox',
    category: VehicleCaptureCategory.interior,
    label: 'Glove Box',
    instruction: 'Open and capture the glove box',
  );
  static const doorSillsPillars = VehicleSide(
    id: 'doorSillsPillars',
    category: VehicleCaptureCategory.interior,
    label: 'Door Sills / Pillars',
    instruction: 'Capture the door sill or pillar VIN/data sticker clearly',
    requiresLevel: false,
  );
  static const pedals = VehicleSide(
    id: 'pedals',
    category: VehicleCaptureCategory.interior,
    label: 'Pedals',
    instruction: 'Capture the pedals clearly',
    requiresLevel: false,
  );
  static const seatBelts = VehicleSide(
    id: 'seatBelts',
    category: VehicleCaptureCategory.interior,
    label: 'Seat Belts',
    instruction: 'Capture the seat belts clearly',
  );
  static const cargoArea = VehicleSide(
    id: 'cargoArea',
    category: VehicleCaptureCategory.interior,
    label: 'Cargo Area',
    instruction: 'Capture the rear cargo area clearly',
  );
  static const thirdRowSeats = VehicleSide(
    id: 'thirdRowSeats',
    category: VehicleCaptureCategory.interior,
    label: 'Third Row Seats',
    instruction: 'Capture the third-row seats clearly',
  );
  static const underSeatArea = VehicleSide(
    id: 'underSeatArea',
    category: VehicleCaptureCategory.interior,
    label: 'Under Seat Area',
    instruction: 'Capture underneath the seats clearly',
    requiresLevel: false,
  );
  static const floorMatsCarpet = VehicleSide(
    id: 'floorMatsCarpet',
    category: VehicleCaptureCategory.interior,
    label: 'Floor Mats / Carpet',
    instruction: 'Capture the floor mats and carpet condition',
    requiresLevel: false,
  );

  // ---------------------------------------------------------------------
  // Groupings.
  // ---------------------------------------------------------------------

  /// The 6 exterior angles a flow captures unless told otherwise.
  static const List<VehicleSide> defaultExterior = [
    front,
    frontRight,
    frontSide,
    rearRight,
    rear,
    rearLeft,
  ];

  /// The 6 interior angles a flow captures unless told otherwise.
  static const List<VehicleSide> defaultInterior = [
    dashboard,
    cockpit,
    trunk,
    console,
    roof,
    driverDoor,
  ];

  /// [defaultExterior] + [defaultInterior] — what [CaptureFlow] and
  /// [CameraScreen] fall back to when no explicit step list is given.
  static const List<VehicleSide> defaultValues = [
    ...defaultExterior,
    ...defaultInterior,
  ];

  /// Every built-in exterior angle, default set included — for "add an
  /// angle" pickers that want to offer more than the default.
  static const List<VehicleSide> catalogExterior = [
    ...defaultExterior,
    driverSideProfile,
    passengerSideProfile,
    wheelFrontLeft,
    wheelFrontRight,
    wheelRearLeft,
    wheelRearRight,
    windshield,
    rearWindshield,
    headlights,
    taillights,
    grille,
    licensePlate,
    vinPlate,
    exteriorRoof,
    undercarriage,
    fuelDoor,
    sideMirrors,
    exhaustPipe,
    sunroofExterior,
    engineBay,
  ];

  /// Every built-in interior angle, default set included.
  static const List<VehicleSide> catalogInterior = [
    ...defaultInterior,
    instrumentCluster,
    frontSeats,
    rearSeats,
    passengerDoor,
    rearDoor,
    headliner,
    sunroofInterior,
    steeringWheel,
    infotainmentScreen,
    gloveBox,
    doorSillsPillars,
    pedals,
    seatBelts,
    cargoArea,
    thirdRowSeats,
    underSeatArea,
    floorMatsCarpet,
  ];

  /// Every built-in angle this package knows about — [catalogExterior] +
  /// [catalogInterior].
  static const List<VehicleSide> catalog = [
    ...catalogExterior,
    ...catalogInterior,
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
/// Defaults to [VehicleSide.defaultValues] (6 exterior + 6 interior
/// angles). Pass [sides] to capture a different subset or order — e.g. a
/// larger set drawn from [VehicleSide.catalog], one [VehicleCaptureCategory]
/// only, or with consumer-specific/custom steps appended.
class CaptureFlow {
  CaptureFlow({List<VehicleSide>? sides})
      : steps = (sides ?? VehicleSide.defaultValues)
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
