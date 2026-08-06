import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vehicle_frame_capture_example/main.dart';

void main() {
  testWidgets('shows the three capture entry points', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Capture Vehicle Images'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Quick capture (no review screen)'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(
        ElevatedButton,
        'Capture with bundled review screen',
      ),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ElevatedButton, 'Themed, exterior-only capture'),
      findsOneWidget,
    );
  });
}
