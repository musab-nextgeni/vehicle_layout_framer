# Changelog

## [4.0.1] - 2026-08-20

### Fixed
- iOS: the camera preview and the captured photo could each end up rotated relative to what the user actually saw, because `CameraController` tracks physical device orientation independently of the app's forced landscape UI, and (separately) `lockCaptureOrientation`'s `landscapeLeft`/`landscapeRight` mapping for the still-photo pipeline is inverted from the one that fixes the live preview. `CameraScreen` now locks the UI to `landscapeRight` and the still-capture orientation to `landscapeLeft` on iOS specifically. Android is unaffected — it never had this bug — and keeps its original unrestricted landscape behavior.

### Chore
- Added `analysis_options.yaml` to this package. `flutter_lints` was already a `dev_dependency` but had no `analysis_options.yaml` wiring it in, so analysis was silently running with bare Dart defaults instead of the ruleset the package claims to use.
- Reformatted the package with `dart format` for a clean `flutter pub publish` git-state check.

## [4.0.0] - 2026-08-20

### Breaking changes
- `VehicleSide` is no longer an `enum` — it's a plain class with `id`, `category`, `label`, `instruction`, and `requiresLevel` fields. `VehicleSide.values` no longer exists (use `VehicleSide.defaultValues` or `VehicleSide.catalog` instead), and it can no longer be used in exhaustive `switch` statements or as a `const` pattern outside this package.
- Reshaped the default angle set and grew it from 9 to 12 steps. `left`/`right` (single side-profile shots) are replaced by four corner/side angles — `frontRight`/`frontSide`/`rearRight`/`rearLeft`; `insideFrontRow`/`insideBackRow`/`dashboardOdometer` are replaced by `cockpit`/`driverDoor`/`dashboard`. `CaptureFlow`/`CameraScreen` now default to `VehicleSide.defaultValues` (6 exterior + 6 interior) instead of the old 9.
- `CameraScreen.levelYTolerance`/`levelZTolerance` defaults changed from `1.0`/`2.0` to `2.0`/`3.0` (m/s²) — the level check was too strict to comfortably hold by hand.
- The internal single-axis horizon-line indicator (`LevelHorizonPainter`) is replaced by `LevelCrosshairPainter`, a two-axis bubble-level indicator with a different constructor (`bubbleOffset` instead of an externally-applied rotation).

### Added
- `VehicleCaptureCategory` — tags every `VehicleSide` as `exterior` or `interior`, for building tabbed capture UIs.
- `VehicleSide.catalog` (`catalogExterior` + `catalogInterior`) — ~35 additional built-in angles beyond the default 12: wheels, windshield, headlights/taillights, license plate, VIN plate, undercarriage, engine bay, instrument cluster, glove box, seat belts, cargo area, and more.
- `VehicleSide.custom({label, instruction, category, requiresLevel, id})` — define one-off angles outside the catalog at runtime.
- `VehicleSide.requiresLevel` — per-angle opt-out of the device-level check. Set to `false` in the catalog for angles inherently shot tilted up/down (roof, undercarriage, engine bay, wheels, VIN plate, pedals, etc.) so their shutter is never permanently blocked by a level check that could never pass. `CameraScreen` hides the level indicator entirely and always enables the shutter for such steps.
- Two-axis level indicator: roll (Y) and pitch (Z) are now combined into a single crosshair/bubble-level reticle instead of a rotating horizon line driven by roll alone.

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
