import 'package:flutter_test/flutter_test.dart';
import 'package:relief_dashboard/models/user_model.dart';

import 'helpers/test_harness.dart';

void main() {
  test('seedInitialData creates a warehouse and inventory items', () async {
    final harness = TestHarness();

    await harness.firestoreService.seedInitialData();

    final warehouses = await harness.firestore.collection('warehouses').get();
    final inventory = await harness.firestore.collection('inventory').get();

    expect(warehouses.docs, hasLength(1));
    expect(inventory.docs, isNotEmpty);
  });

  test('seedInitialData is a no-op if a warehouse already exists', () async {
    final harness = TestHarness();

    await harness.firestoreService.seedInitialData();
    await harness.firestoreService.seedInitialData();

    final warehouses = await harness.firestore.collection('warehouses').get();
    expect(warehouses.docs, hasLength(1));
  });

  test(
    'seedDemoAccounts creates a Firestore profile for the demo accounts '
    '(regression test for the "profile not found" bootstrap bug)',
    () async {
      final harness = TestHarness();

      await harness.authService.seedDemoAccounts();

      final users = await harness.firestore.collection('users').get();
      final roles = users.docs.map((d) => d.data()['role']).toSet();

      expect(roles, containsAll([UserModel.roleAdmin, UserModel.roleVolunteer]));
    },
  );

  test(
    'seedDemoAccounts repairs a missing profile even when the auth '
    'account already exists (the original bug: sign-in succeeded but no '
    'Firestore document was ever created for it)',
    () async {
      final harness = TestHarness();

      // Simulate the broken state: seed once, then wipe just the Firestore
      // profile documents while the (mock) auth accounts remain "existing".
      await harness.authService.seedDemoAccounts();
      final usersBefore = await harness.firestore.collection('users').get();
      for (final doc in usersBefore.docs) {
        await doc.reference.delete();
      }
      final emptyCheck = await harness.firestore.collection('users').get();
      expect(emptyCheck.docs, isEmpty);

      // Re-running seeding must repair the missing profiles, not silently
      // skip them because the auth accounts already "exist".
      await harness.authService.seedDemoAccounts();

      final usersAfter = await harness.firestore.collection('users').get();
      expect(usersAfter.docs, isNotEmpty);
    },
  );
}
