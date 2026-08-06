# Changelog

## [3.0.0] - 2026-08-06

### Breaking changes
- `CameraScreen` no longer shows a review screen by default. Previously it always navigated to `SummaryScreen` after the last step; now it pops immediately with the captured `List<File>` unless you pass `showSummary: true`.
- `VehicleFramePainter`, `CaptureButton`, and the internal `LevelHorizonPainter` no longer hardcode `Colors.greenAccent`/`Colors.white` — they take `readyColor`/`idleColor` parameters (both default to the same colors as before, so uncustomized call sites keep the same look).
- `CaptureFlow()` now takes an optional `sides: List<VehicleSide>?` parameter instead of always building all 9 steps internally. Passing nothing still defaults to all 9, in the same order.
- Dropped the `google_fonts` dependency. All text styling now goes through `VehicleCaptureTheme` (falling back to the ambient `Theme` when not overridden) instead of a hardcoded font.
- `SummaryScreen` now takes a `theme: VehicleCaptureTheme` parameter instead of hardcoded colors, and is exported from the library (`export 'src/screens/summary_screen.dart'`) so it can be reused standalone.

### Added
- `VehicleCaptureTheme` — colors (`readyColor`, `idleColor`, `dangerColor`, `primaryColor`, `summaryBackgroundColor`) and optional text styles for the whole flow.
- `CameraScreen.theme` — pass a `VehicleCaptureTheme` to restyle the entire flow.
- `CameraScreen.steps` — capture a custom subset/order of `VehicleSide`s instead of always all 9.
- `CameraScreen.resolutionPreset` and `preferredLensDirection` — configurable camera quality and front/back selection (falls back to the first available camera if the preferred lens isn't found).
- `CameraScreen.levelYTolerance`/`levelZTolerance` — tune how strict the "level" check is.
- `CameraScreen.onPhotoCaptured` and `onStepChanged` callbacks — react to progress live instead of only getting a result at the end.

## [2.0.0] - 2026-08-06

### Breaking changes
- `VehicleFramePainter` no longer takes a `side` parameter and its `isDetected` field is renamed to `isReady` — it now draws one universal rectangular frame for every step instead of a per-side car-silhouette shape.
- `CaptureButton`'s `isDetected` field is renamed to `isReady`.
- Removed on-device object detection entirely (previously backed by `google_mlkit_object_detection`). The "ready" (green) state now reflects device level only.
- `VehicleSide` gained 3 new values: `engineBay`, `dashboardOdometer`, `trunk` — `CaptureFlow` now has 9 steps instead of 6.
- `CameraScreen` now manages its own orientation lifecycle (locks landscape on entry, restores portrait on exit) instead of requiring the caller to do so.

### Changed
- Replaced the six hand-drawn car-silhouette `Path`s with a single rounded-rectangle overlay.
- Fixed the camera preview stretching in landscape (now sized to its native aspect ratio via `FittedBox`/`BoxFit.cover` and cropped instead of distorted).
- Fixed the horizon-level indicator pivoting off-center (it swung like a lever anchored at one end instead of rotating evenly from its middle).
- Sensor-driven UI updates (device level, tilt angle) now use `ValueNotifier`/`ValueListenableBuilder` instead of whole-screen `setState`, so the camera preview and other static UI no longer rebuild on every accelerometer sample.
- Switched from the deprecated `accelerometerEvents` to `accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)`.
- License changed from a proprietary license to MIT.

### Removed
- `google_mlkit_object_detection`, `image`, `image_picker`, `lottie`, `path`, and `path_provider` dependencies — none were exercised by this package's code.

## [1.0.0] - 2026-02-10

### Added
- Initial release of vehicle_frame_capture package
- 6 capture modes: Front, Left, Right, Back, Inside Front Row, Inside Back Row
- Custom frame overlays for each vehicle view
- Device leveling detection using gyroscope/accelerometer
- Visual feedback (green highlight) when vehicle is detected and device is level
- Automatic capture flow management
- `VehicleFramePainter` widget for drawing custom frames
- `CaptureFlow` model for managing capture state
- `CameraScreen` widget for camera integration
- Complete documentation and examples
