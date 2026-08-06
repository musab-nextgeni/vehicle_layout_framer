# Vehicle Detection — Knowledge Base

## 1. What is actually happening

The feature is named "vehicle detection" throughout the codebase (`ObjectDetectionService`,
`detectVehicleInFrame`, `VehicleFramePainter`), but **it does not recognize vehicles**. It uses
Google ML Kit's stock, category-agnostic on-device Object Detection & Tracking (ODT) model and
reduces the result to a simple geometric question: *is something roughly centered in the camera
frame?*

### Data flow

```
CameraController.startImageStream
  -> CameraImage (nv21 on Android / bgra8888 on iOS)
  -> _processCameraImage()                      [camera_screen.dart]
       - drops the frame if a previous inference is still running (_isBusy guard)
  -> ObjectDetectionService.detectVehicleInFrame()   [object_detection_service.dart]
       - _inputImageFromCameraImage(): rotation/format conversion -> InputImage
       - ObjectDetector.processImage(InputImage)     <- native ML Kit inference (base model)
       - for each DetectedObject: normalize boundingBox, compute center (cx, cy)
       - geometric check: 0.15 < cx < 0.85 AND 0.15 < cy < 0.85  -> bool
  -> setState(_isDetected)
       -> VehicleFramePainter (green highlight / fill on the overlay frame)
       -> CaptureButton (enabled only when _isDetected && _isLevel)

(separate, independent path)
CaptureButton.onTap -> CameraController.takePicture() -> full-res JPEG saved to capture flow
```

Key facts:

- `ObjectDetectorOptions` is used with no local/custom model path, which forces ML Kit's
  bundled **base** model — not a project-trained or vehicle-specific one.
- `classifyObjects: true` asks ML Kit to also run a 5-bucket classifier
  (`Fashion good`, `Food`, `Home good`, `Place`, `Plant` — no "Vehicle"/"Car" category exists).
  **The app never reads `detectedObject.labels`** — this classification is computed and thrown
  away on every single frame.
- `multipleObjects: false` — ML Kit returns only its single most prominent object per frame.
- "Detected" = *any* returned object's bounding-box center falls inside the central 70% of the
  frame (`x, y ∈ (0.15, 0.85)`). A person, a box, a poster on a wall — anything ML Kit localizes
  as "an entity" and that happens to be centered — will flip `_isDetected` to `true`.
- Detection only drives UI feedback (frame color, capture-button enablement). The actual photo
  capture (`_takePicture` / `CameraController.takePicture()`) is a fully separate path — a
  misfire in detection can at worst let the user tap capture on a wrong subject, it can't corrupt
  or crop the saved photo.

### Bundled model assets (found in native build output — not Flutter `assets/`)

| File | Role | Size |
|---|---|---|
| `localizer_with_validation.tflite` | category-agnostic object localizer (SSD-style) | ~1.2 MB |
| `labeler_with_validation.tflite` | 5-bucket classifier — **output unused by app code** | ~1.6 MB |
| `mobile_object_localizer_3_1_anchors.pb` | anchor boxes for the localizer | ~150 KB |
| `mobile_object_localizer_labelmap` | generic "Entity" labelmap | negligible |

These ship via the native `com.google.mlkit:object-detection` AAR / iOS ML Kit pod, pulled in
transitively by `google_mlkit_object_detection: ^0.16.0` — they are not Flutter asset files and
don't appear under the project's own `assets/`.

## 2. Pros of the current approach

- **On-device / offline** — no network dependency, no per-inference cost, works without
  connectivity, no data leaves the device (privacy-friendly).
- **No training or model-maintenance burden** — uses Google's pre-trained, actively maintained
  ODT model; no dataset, no retraining pipeline, no model-drift risk.
- **Mature, cross-platform plugin** — one Dart API (`google_mlkit_object_detection`) covers both
  Android and iOS with consistent behavior.
- **Real-time streaming mode** with a simple, effective backpressure mechanism — the `_isBusy`
  flag drops incoming frames while an inference is in flight instead of queuing them, avoiding
  memory buildup or lag spirals.
- **Decoupled from actual capture** — detection is purely an assistive UI hint; a false
  positive/negative doesn't touch the saved photo, keeping the failure mode low-stakes.

## 3. Cons of the current approach

- **Not actually vehicle-specific.** It's a generic "is anything centered" gate. Any centered
  object triggers the same "detected" UI a car would.
- **Wasted computation & size for an unused signal.** `classifyObjects: true` runs a second
  ~1.6 MB model on every frame whose result (`.labels`) is never inspected.
- **Single-object mode can miss the vehicle.** `multipleObjects: false` returns only ML Kit's one
  most-prominent object; if something else in frame is judged more prominent, the vehicle itself
  may never be evaluated.
- **No exposed confidence threshold.** The base `ObjectDetectorOptions` (as opposed to
  `LocalObjectDetectorOptions`/`FirebaseObjectDetectorOptions`) doesn't expose a tunable
  confidence cutoff from Dart — behavior can't be tightened without switching detector modes.
- **Misleading naming.** `ObjectDetectionService.detectVehicleInFrame` reads like a
  vehicle-recognition API; anyone unfamiliar with the internals could overestimate its accuracy
  or misjudge what a refactor is safe to touch.
- **Dead/duplicate code.** A near-identical, unused copy of this entire feature lives under
  `packages/vehicle_frame_capture/` (not referenced by the app's `pubspec.yaml`) — a maintenance
  trap where a fix applied to one copy is silently missing from the other.
- **Orphaned assets.** `assets/front_frame.png`, `back_frame.png`, `left_frame.png`,
  `right_frame.png` are bundled via `assets: - assets/` in `pubspec.yaml` but referenced by zero
  Dart code.

## 4. What can be excluded to shrink app size, keeping ~the same solution

Ordered by impact, all with effectively no behavior change:

1. **Set `classifyObjects: false`** in `ObjectDetectorOptions`
   (`lib/services/object_detection_service.dart`). Since the classification label is never read,
   this is the single highest-value change: it drops the ~1.6 MB `labeler_with_validation.tflite`
   model and its per-frame inference cost entirely, with **zero observable behavior change**
   (the detection/"centered object" logic doesn't use classification at all).
2. **Delete the 4 orphaned PNGs** in `assets/` (`front_frame.png`, `back_frame.png`,
   `left_frame.png`, `right_frame.png`) — zero references, pure dead weight.
3. **Remove the commented-out `# tflite_flutter: ^0.12.1`** line from `pubspec.yaml` — no size
   impact (it's commented out and unresolved), but it's noise suggesting a custom-model
   integration that was never built.
4. *(Not applied — flagged as an aggressive option, not a straightforward exclusion):* dropping
   ML Kit's ODT entirely in favor of a hand-rolled motion/contrast heuristic would save the most
   (~2.8 MB of model weight plus the ML Kit plugin/runtime overhead), but that changes the
   underlying detection approach and its accuracy characteristics — it is a different solution,
   not a trim of the existing one.

Combined, items 1–3 remove the only genuinely wasted model weight and dead assets while leaving
the detection heuristic, its accuracy, and all UI behavior identical.
