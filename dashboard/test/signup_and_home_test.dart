import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relief_dashboard/models/user_model.dart';

import 'helpers/test_harness.dart';

void main() {
  testWidgets('signing up as admin lands on the admin dashboard, not stuck', (
    tester,
  ) async {
    final harness = TestHarness();
    await tester.pumpWidget(harness.buildApp());
    await tester.pumpAndSettle();

    // Starts on the login screen.
    expect(find.byKey(const Key('login_email')), findsOneWidget);

    await tester.tap(find.byKey(const Key('login_signup_link')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('signup_name')), 'QA Admin');
    await tester.enterText(
      find.byKey(const Key('signup_email')),
      'qa_admin@relief.demo',
    );
    await tester.enterText(
      find.byKey(const Key('signup_phone')),
      '+92-000-1111111',
    );
    await tester.tap(find.byKey(const Key('signup_role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coordinator (Admin)').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('signup_password')),
      'demo123456',
    );
    await tester.enterText(
      find.byKey(const Key('signup_confirm')),
      'demo123456',
    );

    await tester.tap(find.byKey(const Key('signup_submit')));
    await tester.pumpAndSettle();

    // Must land on Admin Home directly, no "profile not found" dead end.
    expect(find.text('Relief Coordinator'), findsOneWidget);
    expect(find.text('User profile not found.'), findsNothing);

    // The Firestore profile document must actually exist with the chosen role.
    final users = await harness.firestore.collection('users').get();
    expect(users.docs, hasLength(1));
    expect(users.docs.first.data()['role'], UserModel.roleAdmin);
  });

  testWidgets(
    'signing up as volunteer lands on volunteer home, not stuck',
    (tester) async {
      final harness = TestHarness();
      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_signup_link')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('signup_name')),
        'QA Volunteer',
      );
      await tester.enterText(
        find.byKey(const Key('signup_email')),
        'qa_vol@relief.demo',
      );
      await tester.enterText(
        find.byKey(const Key('signup_phone')),
        '+92-000-2222222',
      );
      // Role defaults to Field Volunteer.
      await tester.enterText(
        find.byKey(const Key('signup_password')),
        'demo123456',
      );
      await tester.enterText(
        find.byKey(const Key('signup_confirm')),
        'demo123456',
      );

      await tester.tap(find.byKey(const Key('signup_submit')));
      await tester.pumpAndSettle();

      expect(find.text('Relief Dashboard'), findsWidgets);
      expect(find.text('User profile not found.'), findsNothing);

      final users = await harness.firestore.collection('users').get();
      expect(users.docs.first.data()['role'], UserModel.roleVolunteer);
    },
  );

  testWidgets('sign out returns to the login screen', (tester) async {
    final harness = TestHarness();
    await tester.pumpWidget(harness.buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('login_signup_link')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signup_name')), 'QA Admin');
    await tester.enterText(
      find.byKey(const Key('signup_email')),
      'qa_admin2@relief.demo',
    );
    await tester.enterText(
      find.byKey(const Key('signup_phone')),
      '+92-000-1111111',
    );
    await tester.tap(find.byKey(const Key('signup_role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coordinator (Admin)').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('signup_password')),
      'demo123456',
    );
    await tester.enterText(
      find.byKey(const Key('signup_confirm')),
      'demo123456',
    );
    await tester.tap(find.byKey(const Key('signup_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Relief Coordinator'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin_logout')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_email')), findsOneWidget);
  });
}
