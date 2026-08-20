import 'package:flutter/material.dart';

/// A capture shutter button. [isReady] only drives its visual style (color,
/// icon) — [onTap] always fires on tap, regardless of [isReady], so the
/// caller decides whether "not ready" should block capture or just show a
/// hint.
class CaptureButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isReady;
  final bool isTakingPicture;
  final Color readyColor;
  final Color idleColor;

  const CaptureButton({
    super.key,
    required this.onTap,
    required this.isReady,
    this.isTakingPicture = false,
    this.readyColor = Colors.greenAccent,
    this.idleColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isReady ? readyColor : idleColor.withValues(alpha: 0.3),
            width: 4,
          ),
        ),
        child: Container(
          height: 65,
          width: 65,
          decoration: BoxDecoration(
            color: isReady ? idleColor : idleColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: isTakingPicture
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                )
              : (!isReady
                    ? Icon(
                        Icons.camera_alt_outlined,
                        color: idleColor.withValues(alpha: 0.5),
                      )
                    : null),
        ),
      ),
    );
  }
}
