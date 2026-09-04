import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:relief_dashboard/main.dart';

void main() {
  testWidgets('App renders setup placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SetupPlaceholderScreen()),
    );

    expect(find.text('Relief Dashboard'), findsOneWidget);
    expect(find.text('Setup OK — Firebase initialized'), findsOneWidget);
  });
}
