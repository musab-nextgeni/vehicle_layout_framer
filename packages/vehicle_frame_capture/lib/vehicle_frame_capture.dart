/// A guided, multi-angle vehicle photo capture flow: a rectangular frame
/// overlay, live device-level feedback, and camera integration in one
/// widget. See [CameraScreen] for the main entry point.
library;

// Re-exported so callers can set CameraScreen.resolutionPreset /
// preferredLensDirection without adding `camera` as a direct dependency.
export 'package:camera/camera.dart' show ResolutionPreset, CameraLensDirection;

// Export models
export 'src/models/capture_flow_model.dart';

// Export theme
export 'src/theme/vehicle_capture_theme.dart';

// Export widgets
export 'src/widgets/vehicle_frame_painter.dart';

// Export screens
export 'src/screens/camera_screen.dart';
export 'src/screens/summary_screen.dart';
