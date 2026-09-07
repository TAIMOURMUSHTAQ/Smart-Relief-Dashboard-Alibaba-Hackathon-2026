import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relief_dashboard/models/relief_request.dart';

import 'helpers/test_harness.dart';

Future<void> _signUp(
  WidgetTester tester, {
  required String name,
  required String email,
  required String phone,
  required String role,
}) async {
  await tester.tap(find.byKey(const Key('login_signup_link')));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('signup_name')), name);
  await tester.enterText(find.byKey(const Key('signup_email')), email);
  await tester.enterText(find.byKey(const Key('signup_phone')), phone);
  if (role == 'admin') {
    await tester.tap(find.byKey(const Key('signup_role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coordinator (Admin)').last);
    await tester.pumpAndSettle();
  }
  await tester.enterText(find.byKey(const Key('signup_password')), 'demo123456');
  await tester.enterText(find.byKey(const Key('signup_confirm')), 'demo123456');
  await tester.tap(find.byKey(const Key('signup_submit')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a request submitted by a volunteer (existing inventory item) is '
    'visible to an admin on a separate session sharing the same backend',
    (tester) async {
      final sharedFirestore = FakeFirebaseFirestore();

      // Admin seeds inventory first, as it would in real usage.
      final adminHarness = TestHarness(sharedFirestore: sharedFirestore);
      await adminHarness.firestoreService.seedInitialData();

      // Volunteer, a completely separate app session/device, signs up and
      // submits a request against an existing inventory item.
      final volunteerHarness = TestHarness(sharedFirestore: sharedFirestore);
      await tester.pumpWidget(volunteerHarness.buildApp());
      await tester.pumpAndSettle();

      await _signUp(
        tester,
        name: 'QA Volunteer',
        email: 'qa_vol_routing@relief.demo',
        phone: '+92-000-2222222',
        role: 'volunteer',
      );

      expect(find.text('Relief Dashboard'), findsWidgets);

      await tester.enterText(
        find.byKey(const Key('request_area')),
        'QA Flood Zone',
      );
      await tester.enterText(find.byKey(const Key('request_headcount')), '12');

      await tester.tap(find.byKey(const Key('item-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blankets').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('request_submit')));
      await tester.tap(find.byKey(const Key('request_submit')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Request submitted successfully'),
        findsWidgets,
      );

      // Confirm it actually landed in the shared backend collection the
      // admin dashboard reads from.
      final requests = await sharedFirestore.collection('requests').get();
      expect(requests.docs, hasLength(1));
      expect(requests.docs.first.data()['areaName'], 'QA Flood Zone');
      expect(requests.docs.first.data()['itemsNeeded'][0]['itemName'], 'Blankets');
    },
  );

  testWidgets(
    'a request submitted with a custom (non-inventory) item is stored '
    'and routed the same way',
    (tester) async {
      final sharedFirestore = FakeFirebaseFirestore();
      final adminHarness = TestHarness(sharedFirestore: sharedFirestore);
      await adminHarness.firestoreService.seedInitialData();

      final volunteerHarness = TestHarness(sharedFirestore: sharedFirestore);
      await tester.pumpWidget(volunteerHarness.buildApp());
      await tester.pumpAndSettle();

      await _signUp(
        tester,
        name: 'QA Volunteer',
        email: 'qa_vol_custom@relief.demo',
        phone: '+92-000-3333333',
        role: 'volunteer',
      );

      await tester.enterText(
        find.byKey(const Key('request_area')),
        'QA Custom Zone',
      );
      await tester.enterText(find.byKey(const Key('request_headcount')), '4');

      await tester.tap(find.byKey(const Key('item-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other (custom item)').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom-item-0')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('custom-item-0')),
        'Mosquito Nets',
      );

      await tester.ensureVisible(find.byKey(const Key('request_submit')));
      await tester.tap(find.byKey(const Key('request_submit')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Request submitted successfully'),
        findsWidgets,
      );

      final requests = await sharedFirestore.collection('requests').get();
      expect(requests.docs, hasLength(1));
      expect(
        requests.docs.first.data()['itemsNeeded'][0]['itemName'],
        'Mosquito Nets',
      );
    },
  );

  test('allocateStock reduces inventory and approves the request', () async {
    final harness = TestHarness();
    await harness.firestoreService.seedInitialData();

    final inventory = await harness.firestore.collection('inventory').get();
    final blankets = inventory.docs.firstWhere(
      (d) => d.data()['itemName'] == 'Blankets',
    );
    final warehouseId = blankets.data()['warehouseId'] as String;
    final startingQty = blankets.data()['quantity'] as int;

    await harness.firestoreService.addRequest(
      _buildRequest(volunteerId: 'v1', itemName: 'Blankets', qty: 20),
    );
    final requests = await harness.firestore.collection('requests').get();
    final requestId = requests.docs.first.id;

    await harness.firestoreService.allocateStock(
      requestId: requestId,
      allocations: [
        _AllocatedItemLike(
          itemName: 'Blankets',
          qty: 20,
          warehouseId: warehouseId,
        ).toAllocatedItem(),
      ],
    );

    final updatedInventory =
        await harness.firestore.collection('inventory').doc(blankets.id).get();
    expect(updatedInventory.data()!['quantity'], startingQty - 20);

    final updatedRequest =
        await harness.firestore.collection('requests').doc(requestId).get();
    expect(updatedRequest.data()!['status'], 'Approved');
  });

  test(
    'allocateStock refuses to over-allocate beyond available stock',
    () async {
      final harness = TestHarness();
      await harness.firestoreService.seedInitialData();

      final inventory = await harness.firestore.collection('inventory').get();
      final blankets = inventory.docs.firstWhere(
        (d) => d.data()['itemName'] == 'Blankets',
      );
      final warehouseId = blankets.data()['warehouseId'] as String;
      final startingQty = blankets.data()['quantity'] as int;

      await harness.firestoreService.addRequest(
        _buildRequest(
          volunteerId: 'v1',
          itemName: 'Blankets',
          qty: startingQty + 1000,
        ),
      );
      final requests = await harness.firestore.collection('requests').get();
      final requestId = requests.docs.first.id;

      expect(
        () => harness.firestoreService.allocateStock(
          requestId: requestId,
          allocations: [
            _AllocatedItemLike(
              itemName: 'Blankets',
              qty: startingQty + 1000,
              warehouseId: warehouseId,
            ).toAllocatedItem(),
          ],
        ),
        throwsA(isA<Exception>()),
      );
    },
  );
}

ReliefRequest _buildRequest({
  required String volunteerId,
  required String itemName,
  required int qty,
}) {
  return ReliefRequest(
    volunteerId: volunteerId,
    areaName: 'Test Area',
    lat: 24.86,
    lng: 67.00,
    headcount: 10,
    urgency: ReliefRequest.urgencyHigh,
    itemsNeeded: [RequestItem(itemName: itemName, qty: qty)],
    status: ReliefRequest.statusPending,
    notes: '',
    allocatedItems: const [],
  );
}

class _AllocatedItemLike {
  final String itemName;
  final int qty;
  final String warehouseId;

  _AllocatedItemLike({
    required this.itemName,
    required this.qty,
    required this.warehouseId,
  });

  AllocatedItem toAllocatedItem() =>
      AllocatedItem(itemName: itemName, qty: qty, warehouseId: warehouseId);
}
