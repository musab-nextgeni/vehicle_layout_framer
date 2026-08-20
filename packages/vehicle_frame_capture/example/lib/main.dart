import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vehicle_frame_capture/vehicle_frame_capture.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Frame Capture Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  Future<void> _startCapture(
    BuildContext context, {
    required bool showSummary,
    List<VehicleSide>? steps,
    VehicleCaptureTheme theme = const VehicleCaptureTheme(),
  }) async {
    final images = await Navigator.push<List<File>>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          showSummary: showSummary,
          steps: steps,
          theme: theme,
          onStepChanged: (side, index, total) =>
              debugPrint('Step ${index + 1}/$total: ${side.label}'),
          onPhotoCaptured: (side, file) =>
              debugPrint('Captured ${side.label} -> ${file.path}'),
        ),
      ),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          images == null
              ? 'Capture cancelled'
              : 'Captured ${images.length} photo(s)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Frame Capture Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Capture Vehicle Images',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Three ways to use the package: the bare default, the '
                'bundled review screen, and a themed flow with a custom '
                'step list.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () =>
                  _startCapture(context, showSummary: false),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Quick capture (no review screen)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _startCapture(context, showSummary: true),
              icon: const Icon(Icons.grid_view),
              label: const Text('Capture with bundled review screen'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _startCapture(
                context,
                showSummary: true,
                steps: VehicleSide.exteriorSides,
                theme: const VehicleCaptureTheme(
                  readyColor: Colors.orangeAccent,
                  primaryColor: Colors.deepPurple,
                ),
              ),
              icon: const Icon(Icons.palette_outlined),
              label: const Text('Themed, exterior-only capture'),
            ),
          ],
        ),
      ),
    );
  }
}
