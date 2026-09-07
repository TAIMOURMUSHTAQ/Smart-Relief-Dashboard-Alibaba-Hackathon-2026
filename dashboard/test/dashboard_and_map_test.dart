import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relief_dashboard/models/relief_request.dart';
import 'package:relief_dashboard/screens/dashboard_screen.dart';
import 'package:relief_dashboard/screens/map_screen.dart';
import 'package:relief_dashboard/services/auth_service.dart';
import 'package:relief_dashboard/services/firestore_service.dart';

import 'helpers/test_harness.dart';

Widget _wrap(TestHarness harness, Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>.value(value: harness.authService),
      ChangeNotifierProvider<FirestoreService>.value(
        value: harness.firestoreService,
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('dashboard shows correct active and critical counts', (
    tester,
  ) async {
    final harness = TestHarness();
    await harness.firestoreService.seedInitialData();

    await harness.firestoreService.addRequest(
      ReliefRequest(
        volunteerId: 'v1',
        areaName: 'Area A',
        lat: 24.8,
        lng: 67.0,
        headcount: 5,
        urgency: ReliefRequest.urgencyCritical,
        itemsNeeded: const [RequestItem(itemName: 'Blankets', qty: 2)],
        status: ReliefRequest.statusPending,
        notes: '',
        allocatedItems: const [],
      ),
    );
    await harness.firestoreService.addRequest(
      ReliefRequest(
        volunteerId: 'v2',
        areaName: 'Area B',
        lat: 24.9,
        lng: 67.1,
        headcount: 3,
        urgency: ReliefRequest.urgencyLow,
        itemsNeeded: const [RequestItem(itemName: 'Rice (5kg bag)', qty: 1)],
        status: ReliefRequest.statusDelivered,
        notes: '',
        allocatedItems: const [],
      ),
    );

    await tester.pumpWidget(_wrap(harness, const DashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Active Requests'), findsOneWidget);
    // Area A is pending (active) and critical; Area B is delivered.
    expect(find.text('1'), findsWidgets);
    expect(find.text('Could not load dashboard data:'), findsNothing);
  });

  testWidgets('map screen renders without error once data loads', (
    tester,
  ) async {
    final harness = TestHarness();
    await harness.firestoreService.seedInitialData();

    await tester.pumpWidget(
      _wrap(harness, const MapScreen(isAdmin: true)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not load map data'), findsNothing);
  });
}
