# vehicle_frame_capture

A guided, multi-angle vehicle photo capture flow for Flutter apps — a live camera preview with a rectangular framing guide that turns green when the device is held level, walking the user through every angle a vehicle listing typically needs.

It's deliberately unopinionated: no review UI, colors, fonts, or step list are forced on you — every one of them is a parameter with a sensible default.

## Features

- 📸 **Configurable capture steps**: defaults to all 9 (Front, Left, Right, Back, Inside Front Row, Inside Back Row, Engine Bay, Dashboard & Odometer, Trunk/Boot), or pass your own subset/order
- 🎯 **Rectangular frame overlay**: a simple, universal framing guide used across every step
- 📱 **Device leveling**: accelerometer-driven level detection, visualized with a horizon-line indicator, with tunable tolerance
- 🎨 **Themeable**: colors and text styles are all overridable via `VehicleCaptureTheme`; text falls back to your app's ambient `Theme` when not overridden — no font package is forced on you
- 🔄 **Capture flow management**: automatic progression, with `onPhotoCaptured`/`onStepChanged` callbacks to react live
- 🖼️ **Review UI is optional**: returns the captured images directly by default; opt into the bundled review screen with `showSummary: true` only if you want it
- 📷 **Camera controls**: pick front/back camera and resolution preset
- ⚡ **Self-contained**: locks to landscape while active and restores portrait on exit — no setup required from the calling app

## Installation

Add this to your app's `pubspec.yaml`:

```yaml
dependencies:
  vehicle_frame_capture: ^3.0.0
```

### Platform setup

This package uses the [`camera`](https://pub.dev/packages/camera) and [`sensors_plus`](https://pub.dev/packages/sensors_plus) plugins, which need camera permissions declared in your app:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed to capture vehicle photos.</string>
```

## Usage

### Bare minimum — no review screen, full default step list

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vehicle_frame_capture/vehicle_frame_capture.dart';

Future<void> startCapture(BuildContext context) async {
  final images = await Navigator.push<List<File>>(
    context,
    MaterialPageRoute(builder: (context) => const CameraScreen()),
  );

  if (images != null) {
    // images.length == 9, one per VehicleSide, in flow order.
    // Build your own review/upload UI with these — CameraScreen doesn't
    // show one unless you ask it to (see below).
  }
}
```

### With the bundled review screen, a custom step list, and theming

```dart
final images = await Navigator.push<List<File>>(
  context,
  MaterialPageRoute(
    builder: (context) => CameraScreen(
      showSummary: true, // shows the bundled SummaryScreen before returning
      steps: const [
        VehicleSide.front,
        VehicleSide.left,
        VehicleSide.right,
        VehicleSide.back,
      ],
      theme: const VehicleCaptureTheme(
        readyColor: Colors.orangeAccent,
        primaryColor: Colors.deepPurple,
      ),
      resolutionPreset: ResolutionPreset.high,
      preferredLensDirection: CameraLensDirection.back,
      onStepChanged: (side, index, total) =>
          debugPrint('Step ${index + 1}/$total: ${side.label}'),
      onPhotoCaptured: (side, file) =>
          debugPrint('Captured ${side.label} -> ${file.path}'),
    ),
  ),
);
```

`CameraScreen` handles the entire flow internally — camera preview, leveling, the frame overlay, and per-step progression — and returns the captured `List<File>` (or `null` if the user backs out) via the standard `Navigator.pop` result.

## Components

### `CameraScreen`
The capture flow as a single, self-contained screen. Push it and await its result.

| Parameter | Default | Purpose |
|---|---|---|
| `steps` | all 9 `VehicleSide.values` | Which sides to capture, in order |
| `theme` | `VehicleCaptureTheme()` | Colors and text styles |
| `showSummary` | `false` | Show the bundled `SummaryScreen` before returning, instead of returning immediately |
| `resolutionPreset` | `ResolutionPreset.medium` | Camera capture quality |
| `preferredLensDirection` | `CameraLensDirection.back` | Which camera to use (falls back to the first available) |
| `levelYTolerance` / `levelZTolerance` | `1.0` / `2.0` | How strict the "level" check is |
| `onPhotoCaptured` | `null` | `(VehicleSide, File)` called after each photo is saved |
| `onStepChanged` | `null` | `(VehicleSide, int index, int total)` called on each step transition |

### `VehicleCaptureTheme`
Colors (`readyColor`, `idleColor`, `dangerColor`, `primaryColor`, `summaryBackgroundColor`) and optional text styles (`titleTextStyle`, `instructionTextStyle`, `labelTextStyle`) — anything left null falls back to the ambient `Theme`.

### `SummaryScreen`
The optional review grid shown when `showSummary: true`. Exported standalone too, in case you want to reuse it outside the main flow.

### `VehicleFramePainter`
The `CustomPainter` that draws the rectangular frame guide.

```dart
CustomPaint(
  painter: VehicleFramePainter(isReady: true, readyColor: Colors.green),
  size: Size.infinite,
)
```

### `CaptureFlow`
Manages capture state and progression across a list of `VehicleSide` steps.

```dart
final captureFlow = CaptureFlow(sides: [VehicleSide.front, VehicleSide.back]);
final currentStep = captureFlow.currentStep;
captureFlow.nextStep();
```

### `VehicleSide`
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

## What this package does *not* do

It does not run any on-device object/vehicle detection — the "ready" (green) state reflects device level only, not image content. If you need contents-aware detection, layer it on top by watching the returned images.

## License

MIT — see [LICENSE](LICENSE).
