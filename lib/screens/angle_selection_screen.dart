import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:vehicle_frame_capture/vehicle_frame_capture.dart';

/// Entry point for the guided vehicle capture flow: an Exterior/Interior tab
/// switcher above a grid of [VehicleSide] tiles the user can tap, in any
/// order, to capture (or retake) exactly one photo for that angle.
///
/// Each tap pushes [CameraScreen] configured with a single step, so every
/// camera session captures exactly one photo before returning here. Tapping
/// the red badge on an already-captured tile clears it back to the
/// "Upload or Capture" placeholder without opening the camera.
///
/// Pops with a `Map<VehicleSide, File>` once every angle has been captured
/// and the user taps Done, or `null` if they exit before that.
///
/// ```dart
/// final images = await Navigator.push<Map<VehicleSide, File>>(
///   context,
///   MaterialPageRoute(builder: (_) => const AngleSelectionScreen()),
/// );
/// ```
class AngleSelectionScreen extends StatefulWidget {
  const AngleSelectionScreen({
    super.key,
    this.sides,
    this.theme = const VehicleCaptureTheme(),
    this.resolutionPreset = ResolutionPreset.medium,
    this.preferredLensDirection = CameraLensDirection.back,
    this.levelYTolerance = 2.0,
    this.levelZTolerance = 3.0,
  });

  /// Which [VehicleSide]s to offer. Defaults to [VehicleSide.defaultValues]
  /// (6 exterior + 6 interior angles).
  final List<VehicleSide>? sides;

  /// Colors and text styles used throughout the flow.
  final VehicleCaptureTheme theme;

  /// Forwarded to [CameraScreen] for each single-angle capture.
  final ResolutionPreset resolutionPreset;
  final CameraLensDirection preferredLensDirection;
  final double levelYTolerance;
  final double levelZTolerance;

  @override
  State<AngleSelectionScreen> createState() => _AngleSelectionScreenState();
}

class _AngleSelectionScreenState extends State<AngleSelectionScreen> {
  late final List<VehicleSide> _sides =
      widget.sides ?? VehicleSide.defaultValues;
  late final List<VehicleCaptureCategory> _categories = _sides
      .map((side) => side.category)
      .toSet()
      .toList();

  final Map<VehicleSide, File> _captured = {};

  late VehicleCaptureCategory _selectedCategory = _categories.first;

  bool get _isComplete => _sides.every(_captured.containsKey);

  List<VehicleSide> _sidesFor(VehicleCaptureCategory category) =>
      _sides.where((side) => side.category == category).toList();

  Future<void> _captureSide(VehicleSide side) async {
    final images = await Navigator.push<List<File>>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          steps: [side],
          theme: widget.theme,
          resolutionPreset: widget.resolutionPreset,
          preferredLensDirection: widget.preferredLensDirection,
          levelYTolerance: widget.levelYTolerance,
          levelZTolerance: widget.levelZTolerance,
        ),
      ),
    );

    if (images != null && images.isNotEmpty && mounted) {
      setState(() {
        _captured[side] = images.first;
      });
    }
  }

  void _clearImage(VehicleSide side) {
    setState(() {
      _captured.remove(side);
    });
  }

  // Pops with the captured images when there's a caller to return to.
  // Without one — e.g. this screen is the app's home route — there's
  // nothing to pop back to, so show a confirmation instead.
  void _finish() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(_captured);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All ${_captured.length} photos captured!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final labelStyle =
        theme.labelTextStyle ??
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        );
    final sectionStyle = labelStyle.copyWith(
      color: Colors.grey[600],
      fontSize: 13,
      letterSpacing: 1.1,
    );

    return Scaffold(
      backgroundColor: theme.summaryBackgroundColor,
      appBar: AppBar(
        title: Text('Vehicle Photos', style: labelStyle.copyWith(fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryTabs(
                categories: _categories,
                selected: _selectedCategory,
                readyColor: theme.readyColor,
                labelStyle: labelStyle,
                onSelected: (category) =>
                    setState(() => _selectedCategory = category),
              ),
              const SizedBox(height: 20),
              Text('VEHICLE PHOTOS', style: sectionStyle),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _sidesFor(_selectedCategory).length,
                  itemBuilder: (context, index) {
                    final side = _sidesFor(_selectedCategory)[index];
                    return _AngleTile(
                      side: side,
                      image: _captured[side],
                      labelStyle: labelStyle,
                      onTap: () => _captureSide(side),
                      onClear: () => _clearImage(side),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isComplete ? _finish : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isComplete ? 'Done' : 'Capture all angles to continue',
                    style: labelStyle.copyWith(
                      color: _isComplete ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selected,
    required this.readyColor,
    required this.labelStyle,
    required this.onSelected,
  });

  final List<VehicleCaptureCategory> categories;
  final VehicleCaptureCategory selected;
  final Color readyColor;
  final TextStyle labelStyle;
  final ValueChanged<VehicleCaptureCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final category in categories)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: category == categories.last ? 0 : 8,
              ),
              child: _CategoryTab(
                label: category.label,
                isSelected: category == selected,
                readyColor: readyColor,
                labelStyle: labelStyle,
                onTap: () => onSelected(category),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.readyColor,
    required this.labelStyle,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color readyColor;
  final TextStyle labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? readyColor : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? readyColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: labelStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _AngleTile extends StatelessWidget {
  const _AngleTile({
    required this.side,
    required this.image,
    required this.labelStyle,
    required this.onTap,
    required this.onClear,
  });

  final VehicleSide side;
  final File? image;
  final TextStyle labelStyle;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isCaptured = image != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: isCaptured
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(image!, fit: BoxFit.cover),
                      )
                    : DottedBorderBox(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.grey[400], size: 24),
                            const SizedBox(height: 4),
                            Text(
                              'Upload or\nCapture',
                              textAlign: TextAlign.center,
                              style: labelStyle.copyWith(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              if (isCaptured)
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          side.label,
          textAlign: TextAlign.center,
          style: labelStyle.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

/// A dashed-border container matching the "Upload or Capture" placeholder
/// look. [CustomPaint] is used because [Border] has no built-in dashed
/// style.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: Colors.grey[350]!),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = 16.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
