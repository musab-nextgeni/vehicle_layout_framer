# Vehicle Frame Capture Package - Structure & Usage Guide

## 📦 Package Structure

```
packages/vehicle_frame_capture/
├── lib/
│   ├── vehicle_frame_capture.dart          # Main library export file
│   └── src/
│       ├── models/
│       │   └── capture_flow_model.dart     # VehicleSide/VehicleCaptureCategory + capture flow state
│       ├── theme/
│       │   └── vehicle_capture_theme.dart  # Colors/text styles for the whole flow
│       ├── widgets/
│       │   ├── vehicle_frame_painter.dart  # Rectangular frame overlay painter
│       │   └── capture_button.dart         # Shutter button (internal)
│       └── screens/
│           ├── camera_screen.dart          # Camera capture screen (public entry point)
│           └── summary_screen.dart         # Optional review screen (only shown if requested)
├── example/
│   ├── lib/
│   │   └── main.dart                       # Example app (3 usage variants)
│   └── pubspec.yaml
├── pubspec.yaml                            # Package dependencies
├── README.md                               # Package documentation
├── CHANGELOG.md                            # Version history
└── LICENSE                                 # License information
```

## 🚀 Quick Start

### 1. Add Dependency

In your app's `pubspec.yaml`:

```yaml
dependencies:
  vehicle_frame_capture:
    path: packages/vehicle_frame_capture
```

### 2. Import Package

```dart
import 'package:vehicle_frame_capture/vehicle_frame_capture.dart';
```

### 3. Use CameraScreen

```dart
final images = await Navigator.push<List<File>>(
  context,
  MaterialPageRoute(
    builder: (context) => const CameraScreen(),
  ),
);
```

`CameraScreen` locks the device to landscape on entry and restores portrait on exit automatically — the calling app doesn't need to manage orientation itself. By default it returns `images` as soon as the last step is captured; no review UI is shown unless you ask for one (see below).

## 📸 Capture Flow

By default, the package guides users through `VehicleSide.defaultValues` — 12 steps (6 exterior + 6 interior), in this order:

**Exterior**
1. **Front**
2. **Front Right**
3. **Front Side**
4. **Rear Right**
5. **Rear**
6. **Rear Left**

**Interior**
7. **Dashboard**
8. **Cock Pit**
9. **Trunk**
10. **Console**
11. **Roof**
12. **Driver Door**

Pass `steps:` to `CameraScreen` (or `sides:` to `CaptureFlow` directly) to capture a different subset or order — including angles from the extended `VehicleSide.catalog` (wheels, windshield, VIN plate, engine bay, instrument cluster, and ~30 more) or fully custom ones:

```dart
CameraScreen(
  steps: const [
    VehicleSide.front,
    VehicleSide.frontRight,
    VehicleSide.rearRight,
    VehicleSide.rear,
  ],
)
```

Every `VehicleSide` is tagged with a `VehicleCaptureCategory` (`exterior`/`interior`) — group angles by `side.category` to build tabbed pickers like the one in this repo's app (`lib/screens/angle_selection_screen.dart`).

## 🎨 Features

### Rectangular Frame Overlay
A single, universal rounded-rectangle guide is used across every step — no per-step shapes.

### Device Leveling
Uses the accelerometer (via `sensors_plus`) to detect when the device is level, visualized with a two-axis crosshair/bubble-level indicator — roll (Y) shifts it left/right, pitch (Z) shifts it up/down, and it settles into the center reticle once both are within tolerance. Tune strictness with `levelYTolerance`/`levelZTolerance` (default `2.0`/`3.0`).

Some angles are inherently shot tilted up or down (roof, undercarriage, engine bay, wheels, ...) and would never satisfy a level check. Those set `VehicleSide.requiresLevel = false` in the catalog, which hides the level indicator entirely and always enables the shutter for that step — regardless of `levelYTolerance`/`levelZTolerance`.

### Theming
Everything visual is driven by `VehicleCaptureTheme` — colors and (optionally) text styles. Leave text styles null to inherit your app's ambient `Theme`; no font package is forced on you.

```dart
CameraScreen(
  theme: const VehicleCaptureTheme(
    readyColor: Colors.orangeAccent,
    primaryColor: Colors.deepPurple,
  ),
)
```

### Visual Feedback
- **Idle color outline** (`idleColor`, default white): default state
- **Ready color outline + fill** (`readyColor`, default green): device is level (or the current step doesn't require it), ready to capture

This reflects device level only — the package does not perform any on-device vehicle/object detection.

### Optional Review Screen
`showSummary: false` (the default) returns the captured images directly via `Navigator.pop` — build your own review/upload UI with them. `showSummary: true` shows the bundled `SummaryScreen` (a review grid with a Done button) first.

### Progress Callbacks
`onPhotoCaptured: (side, file) => ...` fires after each photo is saved; `onStepChanged: (side, index, total) => ...` fires on each step transition — use these to react live (e.g. start uploading as photos come in) instead of waiting for the whole flow to finish.

### Camera Controls
`resolutionPreset` (default `ResolutionPreset.medium`) and `preferredLensDirection` (default `CameraLensDirection.back`, falls back to the first available camera if no match) are both configurable.

## 🔧 Components

### VehicleFramePainter
Custom painter that draws the rectangular frame overlay.

```dart
CustomPaint(
  painter: VehicleFramePainter(isReady: true, readyColor: Colors.green),
)
```

### CaptureFlow
Manages capture state and progression over a configurable list of steps.

```dart
final captureFlow = CaptureFlow(sides: [VehicleSide.front, VehicleSide.rear]);
final currentStep = captureFlow.currentStep;
captureFlow.nextStep();
```

### VehicleSide

A plain class, not an enum — so consumers aren't limited to a fixed set of angles:

```dart
class VehicleSide {
  final String id;
  final VehicleCaptureCategory category; // exterior or interior
  final String label;
  final String instruction;
  final bool requiresLevel;
}
```

- `VehicleSide.defaultValues` — the 12 default angles (see above).
- `VehicleSide.catalog` / `catalogExterior` / `catalogInterior` — every built-in angle, defaults included: wheels (front/rear, left/right), windshield/rear windshield, headlights/taillights, grille, license plate, VIN plate, exterior roof, undercarriage, fuel door, side mirrors, exhaust pipe, sunroof (exterior), engine bay; instrument cluster, front/rear seats, passenger/rear door, headliner, sunroof (interior), steering wheel, infotainment screen, glove box, door sills/pillars, pedals, seat belts, cargo area, third-row seats, under-seat area, floor mats/carpet.
- `VehicleSide.custom({label, instruction, category, requiresLevel, id})` — define a runtime, one-off angle the catalog doesn't cover.

### VehicleCaptureCategory

```dart
enum VehicleCaptureCategory { exterior, interior }
```

## 📱 Platform Support

- ✅ Android
- ✅ iOS

(Camera/accelerometer support on macOS/Windows/web depends entirely on the underlying `camera` and `sensors_plus` plugins' own platform support at the version pinned in `pubspec.yaml` — verify against those packages before relying on it.)

## 🔐 Permissions Required

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

### iOS (`Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed to capture vehicle photos.</string>
```

## 📝 Example Usage

See the `example/` directory — it demonstrates three variants: the bare default, the bundled review screen, and a themed flow with a custom step list.

## 🐛 Troubleshooting

### Camera not working
- Ensure camera permissions are granted
- Check that the device has a camera
- Verify camera plugin is properly initialized

### Frame never turns green
- The frame's "ready" state is driven by device level (accelerometer), not by anything in the camera image — hold the device flat/level to trigger it, unless the current step has `requiresLevel: false` (it's always "ready" then)
- Check that the device has an accelerometer and that `sensors_plus` initialized correctly
- If it still feels too strict/lenient, tune `levelYTolerance`/`levelZTolerance`

## 📄 License

MIT — see [LICENSE](LICENSE).
