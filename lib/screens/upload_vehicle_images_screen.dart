import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vehicle_frame_capture/vehicle_frame_capture.dart';

import '../models/vehicle_capture_result.dart';

enum _CaptureChoice { camera, gallery }

/// Review/manage screen shown after the exterior and interior capture flows
/// complete: an Exterior/Interior toggle over a photo grid where any shot can
/// be cleared (red badge) or retaken/uploaded (tap the tile).
class UploadVehicleImagesScreen extends StatefulWidget {
  const UploadVehicleImagesScreen({super.key, required this.initialResult});

  final VehicleCaptureResult initialResult;

  @override
  State<UploadVehicleImagesScreen> createState() =>
      _UploadVehicleImagesScreenState();
}

class _UploadVehicleImagesScreenState
    extends State<UploadVehicleImagesScreen> {
  static const _accentGreen = Color(0xFF5FD068);

  late Map<VehicleSide, File?> _exterior;
  late Map<VehicleSide, File?> _interior;
  bool _isExterior = true;

  @override
  void initState() {
    super.initState();
    _exterior = Map.of(widget.initialResult.exterior);
    _interior = Map.of(widget.initialResult.interior);
  }

  Map<VehicleSide, File?> get _activeMap => _isExterior ? _exterior : _interior;

  List<VehicleSide> get _activeSides =>
      _isExterior ? VehicleSide.exteriorSides : VehicleSide.interiorSides;

  Future<void> _retake(VehicleSide side, Map<VehicleSide, File?> targetMap) async {
    final choice = await showModalBottomSheet<_CaptureChoice>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, _CaptureChoice.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, _CaptureChoice.gallery),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == _CaptureChoice.camera) {
      final files = await Navigator.push<List<File>>(
        context,
        MaterialPageRoute(builder: (context) => CameraScreen(steps: [side])),
      );
      if (files != null && files.isNotEmpty && mounted) {
        setState(() => targetMap[side] = files.first);
      }
    } else {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        setState(() => targetMap[side] = File(picked.path));
      }
    }
  }

  void _clear(VehicleSide side, Map<VehicleSide, File?> targetMap) {
    setState(() => targetMap[side] = null);
  }

  void _onContinue() {
    final missing = [
      for (final entry in _exterior.entries)
        if (entry.value == null) 'Exterior ${entry.key.label}',
      for (final entry in _interior.entries)
        if (entry.value == null) 'Interior ${entry.key.label}',
    ];

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Missing: ${missing.join(', ')}')),
      );
      return;
    }

    debugPrint(
      '[Vehicle capture complete] exterior=${_exterior.length} interior=${_interior.length}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Upload Vehicle Images',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please capture all required images as per the guidelines below.',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              _buildToggle(),
              const SizedBox(height: 24),
              Text(
                'VEHICLE PHOTOS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildGrid()),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleSegment('Exterior', _isExterior)),
          Expanded(child: _buildToggleSegment('Interior', !_isExterior)),
        ],
      ),
    );
  }

  Widget _buildToggleSegment(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _isExterior = label == 'Exterior'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _accentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final sides = _activeSides;
    final map = _activeMap;
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: sides.length,
      itemBuilder: (context, index) {
        final side = sides[index];
        return _buildTile(side, map[side], map);
      },
    );
  }

  Widget _buildTile(
    VehicleSide side,
    File? file,
    Map<VehicleSide, File?> targetMap,
  ) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _retake(side, targetMap),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: file != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(file, fit: BoxFit.cover),
                        )
                      : CustomPaint(
                          painter: _DashedBorderPainter(
                            color: Colors.grey.shade400,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: Colors.grey.shade500),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload or\nCapture',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                if (file != null)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: GestureDetector(
                      onTap: () => _clear(side, targetMap),
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
        ),
        const SizedBox(height: 6),
        Text(
          side.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }
}

/// Dashed rounded-rectangle border for empty photo tiles.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;
  static const _strokeWidth = 1.5;
  static const _dashLength = 6.0;
  static const _gapLength = 4.0;
  static const _radius = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(_radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
