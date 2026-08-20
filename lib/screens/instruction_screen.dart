import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehicle_frame_capture/vehicle_frame_capture.dart';

import '../models/vehicle_capture_result.dart';
import 'upload_vehicle_images_screen.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      // ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Take Vehicle Photos',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Follow these simple steps to get the best results.',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildStep(
                          icon: Icons.wb_sunny_outlined,
                          title: 'Good lighting',
                          description:
                              'Ensure the vehicle is well-lit and avoid shooting against direct sunlight.',
                        ),
                        const SizedBox(height: 24),
                        _buildStep(
                          icon: Icons.center_focus_strong_outlined,
                          title: 'Align the frame',
                          description:
                              'Match the vehicle corners with the on-screen guide lines precisely.',
                        ),
                        const SizedBox(height: 24),
                        _buildStep(
                          icon: Icons.camera_alt_outlined,
                          title: 'Take clear photos',
                          description:
                              'We need clear images of the front, back, and both sides of the vehicle.',
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          height: 60,
                          margin: const EdgeInsets.only(bottom: 30, top: 20),
                          child: ElevatedButton(
                            onPressed: () async {
                              // Exterior and interior are captured as two
                              // separate guided sessions; a null result from
                              // either (user exited mid-flow) aborts back
                              // here rather than proceeding with partial
                              // photos.
                              //
                              // restoreOrientationOnDispose is false here
                              // because the interior CameraScreen is pushed
                              // immediately after — this screen's pop
                              // transition would otherwise restore portrait
                              // after the interior screen's landscape lock,
                              // leaving it stuck in portrait.
                              final exteriorFiles = await Navigator.push<List<File>>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CameraScreen(
                                    steps: VehicleSide.exteriorSides,
                                    restoreOrientationOnDispose: false,
                                  ),
                                ),
                              );
                              if (exteriorFiles == null) {
                                // Aborted mid-exterior-flow: the exterior
                                // screen didn't restore portrait itself, so
                                // do it here before returning.
                                SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.portraitUp,
                                  DeviceOrientation.portraitDown,
                                ]);
                                return;
                              }
                              if (!context.mounted) return;

                              final interiorFiles = await Navigator.push<List<File>>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CameraScreen(
                                    steps: VehicleSide.interiorSides,
                                  ),
                                ),
                              );
                              if (!context.mounted || interiorFiles == null) {
                                return;
                              }

                              final result = VehicleCaptureResult(
                                exterior: Map.fromIterables(
                                  VehicleSide.exteriorSides,
                                  exteriorFiles,
                                ),
                                interior: Map.fromIterables(
                                  VehicleSide.interiorSides,
                                  interiorFiles,
                                ),
                              );

                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UploadVehicleImagesScreen(
                                    initialResult: result,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 5,
                              shadowColor: const Color(
                                0xFF0D47A1,
                              ).withValues(alpha: 0.4),
                            ),
                            child: Text(
                              'Start Scanning',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0D47A1), size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
