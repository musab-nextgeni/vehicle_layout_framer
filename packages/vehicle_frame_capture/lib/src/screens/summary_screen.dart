import 'dart:io';
import 'package:flutter/material.dart';
import '../models/capture_flow_model.dart';
import '../theme/vehicle_capture_theme.dart';

/// Optional review screen shown after the last capture step when
/// `CameraScreen(showSummary: true)` is used — a grid of the captured
/// photos with a Done button that pops with the `List<File>` result.
///
/// Exported so it can also be used standalone, e.g. to re-show a review
/// grid for a [CaptureFlow] built or edited elsewhere.
class SummaryScreen extends StatelessWidget {
  final CaptureFlow flow;
  final VehicleCaptureTheme theme;

  const SummaryScreen({
    super.key,
    required this.flow,
    this.theme = const VehicleCaptureTheme(),
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        theme.titleTextStyle ??
        (Theme.of(context).textTheme.titleLarge ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.bold, color: Colors.black);
    final labelStyle =
        theme.labelTextStyle ??
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w600, fontSize: 16);
    final actionStyle =
        theme.labelTextStyle ??
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle())
            .copyWith(fontSize: 18, fontWeight: FontWeight.w600);

    return Scaffold(
      backgroundColor: theme.summaryBackgroundColor,
      appBar: AppBar(
        title: Text('Capture Summary', style: titleStyle),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: flow.steps.length,
                  itemBuilder: (context, index) {
                    final step = flow.steps[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: step.image != null
                                ? Image.file(step.image!, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              step.side.label,
                              textAlign: TextAlign.center,
                              style: labelStyle,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    final images = flow.steps
                        .map((step) => step.image)
                        .whereType<File>()
                        .toList();
                    Navigator.of(context).pop(images);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Done', style: actionStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
