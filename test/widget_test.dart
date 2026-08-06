import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vehicle_layout_frame_app/main.dart';

void main() {
  testWidgets('shows the instruction screen with a start action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Take Vehicle Photos'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Start Scanning'), findsOneWidget);
  });
}
