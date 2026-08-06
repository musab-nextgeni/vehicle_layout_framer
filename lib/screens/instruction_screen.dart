import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehicle_frame_capture/vehicle_frame_capture.dart';

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
                              // CameraScreen manages its own orientation
                              // lifecycle (locks landscape on entry, restores
                              // portrait on exit) and returns the captured
                              // photos, or null if the user backed out.
                              var files = await Navigator.push<List<File>>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CameraScreen(),
                                ),
                              );
                              print('[Captured files]: ${files?.length ?? 0}');
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
