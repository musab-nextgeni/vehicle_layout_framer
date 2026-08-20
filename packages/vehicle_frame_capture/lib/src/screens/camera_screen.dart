import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import '../models/capture_flow_model.dart';
import '../theme/vehicle_capture_theme.dart';
import '../widgets/capture_button.dart';
import '../widgets/vehicle_frame_painter.dart';
import 'summary_screen.dart';

/// Called after each photo is captured, with the [side] it was taken for
/// and the saved [image] file.
typedef PhotoCapturedCallback = void Function(VehicleSide side, File image);

/// Called whenever the flow advances to a new step.
typedef StepChangedCallback =
    void Function(VehicleSide side, int stepIndex, int totalSteps);

/// Guides the user through a multi-step vehicle photo capture flow, showing
/// a rectangular frame overlay that turns green once the device is held
/// level. The shutter captures on every tap by default regardless of level
/// — see [requireLevelToCapture] to require it instead.
///
/// By default (`showSummary: false`) it returns the captured images via
/// [Navigator.pop] as soon as the last step is captured, leaving any review
/// UI entirely up to the caller:
///
/// ```dart
/// final images = await Navigator.push<List<File>>(
///   context,
///   MaterialPageRoute(builder: (_) => const CameraScreen()),
/// );
/// ```
///
/// Pass `showSummary: true` to use the bundled [SummaryScreen] instead — it
/// shows a review grid and itself pops with the images once the user taps
/// Done.
///
/// This screen manages its own orientation: it locks to landscape while
/// active and restores portrait on exit, so callers can push it without any
/// setup.
class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    this.steps,
    this.theme = const VehicleCaptureTheme(),
    this.showSummary = false,
    this.resolutionPreset = ResolutionPreset.medium,
    this.preferredLensDirection = CameraLensDirection.back,
    this.levelYTolerance = 1.0,
    this.levelZTolerance = 2.0,
    this.onPhotoCaptured,
    this.onStepChanged,
    this.restoreOrientationOnDispose = true,
    this.requireLevelToCapture = false,
  });

  /// Which [VehicleSide]s to capture, in order. Defaults to all 9
  /// [VehicleSide.values].
  final List<VehicleSide>? steps;

  /// Colors and text styles used throughout the flow.
  final VehicleCaptureTheme theme;

  /// If true, navigates to the bundled [SummaryScreen] after the last step
  /// instead of popping immediately with the captured images.
  final bool showSummary;

  /// Camera capture resolution. Higher presets produce larger, higher
  /// quality images at the cost of more processing per frame.
  final ResolutionPreset resolutionPreset;

  /// Which camera to prefer (front or back). Falls back to the first
  /// available camera if none match.
  final CameraLensDirection preferredLensDirection;

  /// Maximum accelerometer Y reading (m/s²) still considered "level".
  final double levelYTolerance;

  /// Maximum accelerometer Z reading (m/s²) still considered "level".
  final double levelZTolerance;

  /// Called after each photo is saved to disk.
  final PhotoCapturedCallback? onPhotoCaptured;

  /// Called whenever the flow advances to a new step.
  final StepChangedCallback? onStepChanged;

  /// If true (the default), restores portrait orientation when this screen
  /// is disposed.
  ///
  /// Set to false when immediately pushing another landscape-locking
  /// [CameraScreen] right after this one (e.g. running exterior and interior
  /// capture as two chained flows) — otherwise this screen's portrait
  /// restore, delayed until its pop transition finishes, can land after the
  /// next screen's landscape lock and leave it stuck in portrait. The last
  /// screen in such a chain should leave this at its default so portrait is
  /// restored once the whole sequence is done.
  final bool restoreOrientationOnDispose;

  /// If false (the default), the shutter always captures on tap — the level
  /// indicator (the frame outline, horizon line, and "DEVICE LEVEL"/"HOLD
  /// STRAIGHT" badge) is shown purely as a framing hint. Some angles (e.g.
  /// looking down into a trunk, or up at a roof) can't be held within the
  /// accelerometer's level tolerance at all, so blocking capture on it would
  /// make those angles uncapturable.
  ///
  /// Set to true to require the device be level before a tap actually takes
  /// a photo (a tap while not level shows a reminder instead).
  final bool requireLevelToCapture;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  late final CaptureFlow _captureFlow;
  bool _isTakingPicture = false;

  // Leveling logic. These are ValueNotifiers rather than State fields
  // because the accelerometer emits at up to 60Hz — routing every sample
  // through setState() would rebuild the entire screen (including the
  // camera preview) that often. ValueListenableBuilder below scopes each
  // rebuild to just the small widgets that actually depend on this data.
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  final ValueNotifier<bool> _isLevelNotifier = ValueNotifier(false);
  final ValueNotifier<double> _tiltAngleNotifier = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _captureFlow = CaptureFlow(sides: widget.steps);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializeCamera();
    _startSensorStream();
  }

  void _startSensorStream() {
    _sensorSubscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.uiInterval,
        ).listen((AccelerometerEvent event) {
          // In landscape:
          // Y is mostly gravity if held upright long-side horizontal.
          // X is gravity if tilted left/right.
          // Z is gravity if tiled forward/back.

          // Calculate the tilt angle for the horizon line.
          // In landscape, X/Y are our primary axes.
          _tiltAngleNotifier.value =
              -event.y / 9.8; // Normalized tilt for a subtle visual effect

          _isLevelNotifier.value =
              event.y.abs() < widget.levelYTolerance &&
              event.z.abs() < widget.levelZTolerance;
        });
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == widget.preferredLensDirection,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      widget.resolutionPreset,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    _initializeControllerFuture?.then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _sensorSubscription?.cancel();
    _isLevelNotifier.dispose();
    _tiltAngleNotifier.dispose();
    if (widget.restoreOrientationOnDispose) {
      // Restore portrait now that the capture flow is done.
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      await _initializeControllerFuture;
      final rawImage = await _controller!.takePicture();
      final file = File(rawImage.path);
      final capturedSide = _captureFlow.currentStep.side;

      _captureFlow.updateImage(file);
      widget.onPhotoCaptured?.call(capturedSide, file);

      if (_captureFlow.currentStepIndex < _captureFlow.steps.length - 1) {
        setState(() {
          _captureFlow.nextStep();
          _isTakingPicture = false;
        });
        widget.onStepChanged?.call(
          _captureFlow.currentStep.side,
          _captureFlow.currentStepIndex,
          _captureFlow.steps.length,
        );
      } else if (mounted) {
        if (widget.showSummary) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SummaryScreen(flow: _captureFlow, theme: widget.theme),
            ),
          );
        } else {
          final images = _captureFlow.steps
              .map((step) => step.image)
              .whereType<File>()
              .toList();
          Navigator.pop(context, images);
        }
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      setState(() {
        _isTakingPicture = false;
      });
    }
  }

  TextStyle _titleStyle(BuildContext context) =>
      widget.theme.titleTextStyle ??
      (Theme.of(context).textTheme.headlineSmall ?? const TextStyle())
          .copyWith(color: Colors.white, fontWeight: FontWeight.bold);

  TextStyle _instructionStyle(BuildContext context) =>
      widget.theme.instructionTextStyle ??
      (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
        color: Colors.white.withValues(alpha: 0.8),
      );

  TextStyle _labelStyle(BuildContext context) =>
      widget.theme.labelTextStyle ??
      (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      );

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = widget.theme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // StackFit.expand forces tight full-screen constraints on this
                // subtree, which would otherwise stretch the camera texture to
                // the screen's aspect ratio. FittedBox+SizedBox instead sizes
                // the preview at its native (landscape-locked) aspect ratio and
                // crops the overflow, avoiding distortion.
                final previewSize = _controller!.value.previewSize!;
                return ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: previewSize.width,
                      height: previewSize.height,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),

          // Overlay
          ValueListenableBuilder<bool>(
            valueListenable: _isLevelNotifier,
            builder: (context, isLevel, _) {
              return CustomPaint(
                painter: VehicleFramePainter(
                  isReady: isLevel,
                  readyColor: theme.readyColor,
                  idleColor: theme.idleColor,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Horizon Level Line
          IgnorePointer(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _tiltAngleNotifier,
                  _isLevelNotifier,
                ]),
                builder: (context, _) {
                  return Transform.rotate(
                    angle: _tiltAngleNotifier.value,
                    child: CustomPaint(
                      painter: LevelHorizonPainter(
                        isLevel: _isLevelNotifier.value,
                        readyColor: theme.readyColor,
                        idleColor: theme.idleColor,
                      ),
                      size: const Size(200, 2),
                    ),
                  );
                },
              ),
            ),
          ),

          // Level Indicator
          Positioned(
            left: 20,
            bottom: 40,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLevelNotifier,
              builder: (context, isLevel, _) {
                final color = isLevel ? theme.readyColor : theme.dangerColor;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLevel ? Icons.check_circle : Icons.error_outline,
                        color: color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLevel ? 'DEVICE LEVEL' : 'HOLD STRAIGHT',
                        style: _labelStyle(context),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Header (Top from landscape)
          Positioned(
            right: MediaQuery.of(context).size.width * 0.3,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _captureFlow.currentStep.side.label,
                  style: _titleStyle(context),
                ),
                Text(
                  _captureFlow.currentStep.side.instruction,
                  style: _instructionStyle(context),
                ),
              ],
            ),
          ),

          // Right Side controls (Capture button)
          Positioned(
            right: 40,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_captureFlow.currentStepIndex + 1}/${_captureFlow.steps.length}',
                  style: _labelStyle(context),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<bool>(
                  valueListenable: _isLevelNotifier,
                  builder: (context, isLevel, _) {
                    return CaptureButton(
                      onTap: (!widget.requireLevelToCapture || isLevel)
                          ? _takePicture
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please hold the device straight',
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                      isReady: isLevel,
                      isTakingPicture: _isTakingPicture,
                      readyColor: theme.readyColor,
                      idleColor: theme.idleColor,
                    );
                  },
                ),
              ],
            ),
          ),

          // Exit button (Top Right Corner or nearby)
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class LevelHorizonPainter extends CustomPainter {
  final bool isLevel;
  final Color readyColor;
  final Color idleColor;

  LevelHorizonPainter({
    required this.isLevel,
    this.readyColor = Colors.greenAccent,
    this.idleColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isLevel ? readyColor : idleColor.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // CustomPaint's canvas origin is the box's top-left corner, not its
    // center, so every point here is drawn relative to centerY to line up
    // with Transform.rotate's pivot (the box's center) — otherwise the line
    // ends up offset from the rotation axis and swings like a lever instead
    // of pivoting evenly from its middle.
    final centerY = size.height / 2;

    // Draw main horizon line
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), paint);

    // Draw center indicator
    final centerPaint = Paint()
      ..color = isLevel ? readyColor : idleColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, centerY), 4, centerPaint);

    // Draw small vertical "notches" at the ends
    canvas.drawLine(Offset(0, centerY - 5), Offset(0, centerY + 5), paint);
    canvas.drawLine(
      Offset(size.width, centerY - 5),
      Offset(size.width, centerY + 5),
      paint,
    );
  }

  @override
  bool shouldRepaint(LevelHorizonPainter oldDelegate) =>
      oldDelegate.isLevel != isLevel ||
      oldDelegate.readyColor != readyColor ||
      oldDelegate.idleColor != idleColor;
}
