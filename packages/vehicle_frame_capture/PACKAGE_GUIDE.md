# Vehicle Frame Capture Package - Structure & Usage Guide

## 📦 Package Structure

```
packages/vehicle_frame_capture/
├── lib/
│   ├── vehicle_frame_capture.dart          # Main library export file
│   └── src/
│       ├── models/
│       │   └── capture_flow_model.dart     # Capture flow state management
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

By default, the package guides users through all 9 `VehicleSide` steps, in this order:

1. **Front** - Exterior front view
2. **Left** - Exterior left side view
3. **Right** - Exterior right side view
4. **Back** - Exterior rear view
5. **Inside Front Row** - Interior front seats
6. **Inside Back Row** - Interior back seats
7. **Engine Bay** - Under the hood
8. **Dashboard & Odometer** - Mileage/dashboard close-up
9. **Trunk / Boot** - Cargo area

Pass `steps:` to `CameraScreen` (or `sides:` to `CaptureFlow` directly) to capture a different subset or order:

```dart
CameraScreen(
  steps: const [VehicleSide.front, VehicleSide.left, VehicleSide.right, VehicleSide.back],
)
```

## 🎨 Features

### Rectangular Frame Overlay
A single, universal rounded-rectangle guide is used across every step — no per-step shapes.

### Device Leveling
Uses the accelerometer (via `sensors_plus`) to detect when the device is level, visualized with a horizon-line indicator. Tune strictness with `levelYTolerance`/`levelZTolerance`.

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
- **Ready color outline + fill** (`readyColor`, default green): device is level, ready to capture

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
final captureFlow = CaptureFlow(sides: [VehicleSide.front, VehicleSide.back]);
final currentStep = captureFlow.currentStep;
captureFlow.nextStep();
```

### VehicleSide Enum
```dart
enum VehicleSide {
  front,
  left,
  right,
  back,
  insideFrontRow,
  insideBackRow,
  engineBay,
  dashboardOdometer,
  trunk,
}
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
- The frame's "ready" state is driven by device level (accelerometer), not by anything in the camera image — hold the device flat/level to trigger it
- Check that the device has an accelerometer and that `sensors_plus` initialized correctly
- If it still feels too strict/lenient, tune `levelYTolerance`/`levelZTolerance`

## 📄 License

MIT — see [LICENSE](LICENSE).
