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
typedef StepChangedCallback = void Function(
    VehicleSide side, int stepIndex, int totalSteps);

/// Guides the user through a multi-step vehicle photo capture flow, showing
/// a rectangular frame overlay that turns green once the device is held
/// level.
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
    this.resolutionPreset = ResolutionPreset.max,
    this.preferredLensDirection = CameraLensDirection.back,
    this.levelYTolerance = 2.0,
    this.levelZTolerance = 3.0,
    this.enableTapToFocus = true,
    this.onPhotoCaptured,
    this.onStepChanged,
  });

  /// Which [VehicleSide]s to capture, in order. Defaults to
  /// [VehicleSide.defaultValues].
  final List<VehicleSide>? steps;

  /// Colors and text styles used throughout the flow.
  final VehicleCaptureTheme theme;

  /// If true, navigates to the bundled [SummaryScreen] after the last step
  /// instead of popping immediately with the captured images.
  final bool showSummary;

  /// Camera capture resolution. Higher presets produce larger, higher
  /// quality images at the cost of more processing per frame. Defaults to
  /// [ResolutionPreset.max], the highest resolution the device supports.
  final ResolutionPreset resolutionPreset;

  /// Which camera to prefer (front or back). Falls back to the first
  /// available camera if none match.
  final CameraLensDirection preferredLensDirection;

  /// Maximum accelerometer Y (roll) reading (m/s²) still considered
  /// "level". Defaults to 2.0 (~11.8° of tilt) — loose enough to hold
  /// steady by hand while still catching an obviously crooked shot.
  final double levelYTolerance;

  /// Maximum accelerometer Z (pitch) reading (m/s²) still considered
  /// "level". Defaults to 3.0 (~17.7° of tilt).
  final double levelZTolerance;

  /// If true, tapping the preview moves focus and exposure metering to the
  /// tapped point, shown with a brief focus ring. Resets to the camera's
  /// default (center) metering on every new step, so a point chosen for one
  /// angle doesn't carry over to the next. Silently does nothing on cameras
  /// that don't support point metering.
  final bool enableTapToFocus;

  /// Called after each photo is saved to disk.
  final PhotoCapturedCallback? onPhotoCaptured;

  /// Called whenever the flow advances to a new step.
  final StepChangedCallback? onStepChanged;

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
  // Normalized (roughly -1..1) roll (Y) and pitch (Z) readings, combined by
  // the crosshair below into a single bubble-level indicator instead of
  // showing left/right tilt alone.
  final ValueNotifier<double> _rollNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> _pitchNotifier = ValueNotifier(0.0);

  // Tap-to-focus. The ring is a ValueNotifier for the same reason as the
  // leveling state above: a tap should only rebuild the ring, not the
  // preview. Taps landing while a metering call is still in flight are
  // coalesced into the latest point instead of queued, so rapid taps don't
  // make the lens hunt through every intermediate position.
  final GlobalKey _stackKey = GlobalKey();
  final ValueNotifier<_FocusTap?> _focusTapNotifier = ValueNotifier(null);
  int _focusTapCount = 0;
  Offset? _pendingMeteringPoint;
  bool _isApplyingMeteringPoint = false;

  @override
  void initState() {
    super.initState();
    _captureFlow = CaptureFlow(sides: widget.steps);
    if (Platform.isIOS) {
      // iOS-only workaround: letting the device rotate between
      // landscapeLeft/Right while the camera plugin tracks *physical*
      // orientation independently is what caused the preview to render
      // rotated on iOS. Pinning to a single fixed orientation (matched by
      // lockCaptureOrientation below) keeps preview and capture in
      // lockstep regardless of how the phone is actually held.
      //
      // This is landscapeRight, not landscapeLeft: Flutter's
      // DeviceOrientation naming is inverted relative to iOS's native
      // UIInterfaceOrientation for landscape — landscapeLeft here rendered
      // upside down on-device. Android's camera plugin doesn't have this
      // quirk and works correctly with both landscape orientations, so it
      // keeps the original unrestricted behavior below.
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    _initializeCamera();
    _startSensorStream();
  }

  void _startSensorStream() {
    _sensorSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((AccelerometerEvent event) {
      // In landscape:
      // Y is roll — gravity component when tilted left/right.
      // Z is pitch — gravity component when tilted forward/back (i.e.
      // pointed up or down).
      _rollNotifier.value = (-event.y / 9.8).clamp(-1.0, 1.0);
      _pitchNotifier.value = (-event.z / 9.8).clamp(-1.0, 1.0);

      _isLevelNotifier.value = event.y.abs() < widget.levelYTolerance &&
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

    _initializeControllerFuture = _controller!.initialize().then((_) async {
      // iOS-only — see the matching Platform.isIOS branch in initState.
      // Without this, the plugin derives still-photo rotation from the
      // device's *physical* orientation independently of the UI lock
      // above, which is what caused the captured file's rotation to
      // mismatch the (already-correct) live preview.
      //
      // This is landscapeLeft, NOT landscapeRight (unlike the UI lock
      // above): on iOS, lockCaptureOrientation's effect on the still-photo
      // pipeline uses an inverted left/right mapping from whatever fixed
      // the live preview — landscapeRight here produced a preview-correct
      // but 180°-flipped *captured file*. Android has neither quirk, so it
      // doesn't need this call at all.
      if (!Platform.isIOS) return;
      await _controller!.lockCaptureOrientation(
        DeviceOrientation.landscapeLeft,
      );
    });
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
    _rollNotifier.dispose();
    _pitchNotifier.dispose();
    _focusTapNotifier.dispose();
    // Restore portrait now that the capture flow is done.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
        _resetMeteringPoint();
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

  void _onPreviewTapUp(TapUpDetails details, Size previewSize) {
    if (_isTakingPicture) return;

    // details.localPosition is in the SizedBox's preview-sized coordinate
    // space (the GestureDetector sits inside the FittedBox), so the
    // BoxFit.cover crop is already accounted for — dividing by previewSize
    // gives the 0..1 point the camera plugin expects.
    final point = Offset(
      (details.localPosition.dx / previewSize.width).clamp(0.0, 1.0),
      (details.localPosition.dy / previewSize.height).clamp(0.0, 1.0),
    );

    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox != null) {
      _focusTapNotifier.value = _FocusTap(
        id: ++_focusTapCount,
        position: stackBox.globalToLocal(details.globalPosition),
      );
    }

    _pendingMeteringPoint = point;
    _drainMeteringPoints();
  }

  Future<void> _drainMeteringPoints() async {
    if (_isApplyingMeteringPoint) return;
    _isApplyingMeteringPoint = true;
    try {
      while (_pendingMeteringPoint != null) {
        final point = _pendingMeteringPoint!;
        _pendingMeteringPoint = null;
        await _applyMeteringPoint(point);
      }
    } finally {
      _isApplyingMeteringPoint = false;
    }
  }

  /// Points focus and exposure at [point], or back at the camera's default
  /// when null. Focus mode itself stays [FocusMode.auto] (continuous), so
  /// the camera keeps refocusing around the point as the user reframes.
  Future<void> _applyMeteringPoint(Offset? point) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      if (controller.value.focusPointSupported) {
        await controller.setFocusPoint(point);
      }
      if (controller.value.exposurePointSupported) {
        await controller.setExposurePoint(point);
      }
    } on CameraException catch (e) {
      debugPrint('Error setting focus/exposure point: $e');
    }
  }

  void _resetMeteringPoint() {
    if (!widget.enableTapToFocus) return;
    _pendingMeteringPoint = null;
    _focusTapNotifier.value = null;
    _applyMeteringPoint(null);
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
    // Angles shot tilted up/down (roof, undercarriage, engine bay, ...) set
    // this to false in the catalog so the horizon-based level check — built
    // for upright, landscape-level shots — never permanently blocks them.
    final requiresLevel = _captureFlow.currentStep.side.requiresLevel;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        key: _stackKey,
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
                final preview = CameraPreview(_controller!);
                return ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: previewSize.width,
                      height: previewSize.height,
                      child: widget.enableTapToFocus
                          ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (details) =>
                                  _onPreviewTapUp(details, previewSize),
                              child: preview,
                            )
                          : preview,
                    ),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),

          // Overlay. IgnorePointer because a full-screen CustomPaint
          // otherwise absorbs every tap meant for the preview underneath.
          IgnorePointer(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLevelNotifier,
              builder: (context, isLevel, _) {
                final effectiveIsLevel = !requiresLevel || isLevel;
                return CustomPaint(
                  painter: VehicleFramePainter(
                    isReady: effectiveIsLevel,
                    readyColor: theme.readyColor,
                    idleColor: theme.idleColor,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // Focus ring at the last tapped point.
          if (widget.enableTapToFocus)
            IgnorePointer(
              child: ValueListenableBuilder<_FocusTap?>(
                valueListenable: _focusTapNotifier,
                builder: (context, tap, _) {
                  if (tap == null) return const SizedBox.shrink();
                  return Stack(
                    children: [
                      Positioned(
                        left: tap.position.dx - _FocusRing.size / 2,
                        top: tap.position.dy - _FocusRing.size / 2,
                        // Keyed per tap so each tap restarts the animation.
                        child: _FocusRing(
                          key: ValueKey(tap.id),
                          color: theme.readyColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // Level Crosshair — combines roll (Y) and pitch (Z) into one
          // bubble-level indicator instead of showing left/right tilt
          // alone, so both axes read at a glance. Hidden for angles shot
          // tilted up/down, where it'd never settle.
          if (requiresLevel)
            IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _rollNotifier,
                    _pitchNotifier,
                    _isLevelNotifier,
                  ]),
                  builder: (context, _) {
                    const maxOffset = 36.0;
                    return CustomPaint(
                      painter: LevelCrosshairPainter(
                        bubbleOffset: Offset(
                          _rollNotifier.value * maxOffset,
                          _pitchNotifier.value * maxOffset,
                        ),
                        isLevel: _isLevelNotifier.value,
                        readyColor: theme.readyColor,
                        idleColor: theme.idleColor,
                      ),
                      size: const Size(140, 140),
                    );
                  },
                ),
              ),
            ),

          // Level Indicator
          if (requiresLevel)
            Positioned(
              left: 20,
              bottom: 40,
              child: IgnorePointer(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isLevelNotifier,
                  builder: (context, isLevel, _) {
                    final color =
                        isLevel ? theme.readyColor : theme.dangerColor;
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
            ),

          // Header (Top from landscape)
          Positioned(
            right: MediaQuery.of(context).size.width * 0.3,
            child: IgnorePointer(
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
                    final canCapture = !requiresLevel || isLevel;
                    return CaptureButton(
                      onTap: canCapture
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
                      isReady: canCapture,
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

class _FocusTap {
  const _FocusTap({required this.id, required this.position});

  final int id;

  /// Tap position in the screen Stack's coordinate space.
  final Offset position;
}

/// A square focus reticle that shrinks into place, holds, then fades out.
class _FocusRing extends StatefulWidget {
  const _FocusRing({super.key, required this.color});

  static const double size = 72;

  final Color color;

  @override
  State<_FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<_FocusRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _scale = Tween(begin: 1.4, end: 1.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
    ),
  );

  late final Animation<double> _opacity = Tween(begin: 1.0, end: 0.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: _FocusRing.size,
          height: _FocusRing.size,
          decoration: BoxDecoration(
            border: Border.all(color: widget.color, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// Draws a bubble-level style reticle: a fixed crosshair + target ring at
/// the center, and a bubble offset by [bubbleOffset] — roll on the x-axis,
/// pitch on the y-axis. The bubble settles into the crosshair once both
/// axes are within tolerance ([isLevel]), showing tilt in both directions
/// at once instead of left/right alone.
class LevelCrosshairPainter extends CustomPainter {
  final Offset bubbleOffset;
  final bool isLevel;
  final Color readyColor;
  final Color idleColor;

  LevelCrosshairPainter({
    required this.bubbleOffset,
    required this.isLevel,
    this.readyColor = Colors.greenAccent,
    this.idleColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final color = isLevel ? readyColor : idleColor.withValues(alpha: 0.6);

    final reticlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Target ring — the zone the bubble needs to settle inside.
    canvas.drawCircle(center, 30, reticlePaint);

    // Crosshair ticks through the center.
    const tickLength = 10.0;
    canvas.drawLine(
      center - const Offset(tickLength, 0),
      center + const Offset(tickLength, 0),
      reticlePaint,
    );
    canvas.drawLine(
      center - const Offset(0, tickLength),
      center + const Offset(0, tickLength),
      reticlePaint,
    );

    // The bubble itself — its distance from center encodes how far off
    // level the device is on the roll and pitch axes simultaneously.
    final bubbleCenter = center + bubbleOffset;
    final bubbleFillPaint = Paint()
      ..color = isLevel ? readyColor : idleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(bubbleCenter, 7, bubbleFillPaint);

    final bubbleOutlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(bubbleCenter, 7, bubbleOutlinePaint);
  }

  @override
  bool shouldRepaint(LevelCrosshairPainter oldDelegate) =>
      oldDelegate.bubbleOffset != bubbleOffset ||
      oldDelegate.isLevel != isLevel ||
      oldDelegate.readyColor != readyColor ||
      oldDelegate.idleColor != idleColor;
}
