import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:relief_dashboard/main.dart' as app;

Future<void> pump(WidgetTester tester, [int seconds = 2]) async {
  await tester.pumpAndSettle(Duration(seconds: seconds));
}

void expectNoVisibleError() {
  expect(find.textContaining('Could not load'), findsNothing);
  expect(find.textContaining('Firebase setup error'), findsNothing);
}

Future<void> tapNavIcon(
  WidgetTester tester,
  Key navBarKey,
  IconData icon,
) async {
  final target = find.descendant(
    of: find.byKey(navBarKey),
    matching: find.byIcon(icon),
  );
  expect(target, findsOneWidget);
  await tester.tap(target);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full app flow: signup, seed, requests, allocation', (
    tester,
  ) async {
    final unique = DateTime.now().millisecondsSinceEpoch;
    final adminEmail = 'qa_admin_$unique@relief.demo';
    final volunteerEmail = 'qa_volunteer_$unique@relief.demo';
    const password = 'demo123456';

    app.main();
    await pump(tester, 5);

    // ---------------- SIGN UP: ADMIN ----------------
    expect(find.byKey(const Key('login_signup_link')), findsOneWidget);
    await tester.tap(find.byKey(const Key('login_signup_link')));
    await pump(tester);

    await tester.enterText(find.byKey(const Key('signup_name')), 'QA Admin');
    await tester.enterText(find.byKey(const Key('signup_email')), adminEmail);
    await tester.enterText(
      find.byKey(const Key('signup_phone')),
      '+92-000-1111111',
    );
    await tester.tap(find.byKey(const Key('signup_role')));
    await pump(tester);
    await tester.tap(find.text('Coordinator (Admin)').last);
    await pump(tester);
    await tester.enterText(find.byKey(const Key('signup_password')), password);
    await tester.enterText(
      find.byKey(const Key('signup_confirm')),
      password,
    );
    await tester.tap(find.byKey(const Key('signup_submit')));
    await pump(tester, 8);

    // Must land on Admin Home, not stuck on signup or "profile not found".
    expect(find.text('Relief Coordinator'), findsOneWidget);
    expect(find.text('User profile not found.'), findsNothing);
    expectNoVisibleError();

    // ---------------- SEED DEMO DATA ----------------
    await tester.tap(find.byKey(const Key('admin_seed')));
    await pump(tester, 6);
    expect(find.textContaining('Demo data and accounts seeded'), findsWidgets);

    // ---------------- CHECK ADMIN TABS ----------------
    const adminNav = Key('admin_bottom_nav');
    await tapNavIcon(tester, adminNav, Icons.inventory_2_outlined);
    await pump(tester, 3);
    expectNoVisibleError();
    expect(find.textContaining('No inventory items yet'), findsNothing);

    await tapNavIcon(tester, adminNav, Icons.assignment_outlined);
    await pump(tester, 3);
    expectNoVisibleError();

    await tapNavIcon(tester, adminNav, Icons.map_outlined);
    await pump(tester, 3);
    expectNoVisibleError();

    await tapNavIcon(tester, adminNav, Icons.dashboard_outlined);
    await pump(tester, 3);
    expectNoVisibleError();

    // ---------------- SIGN OUT ----------------
    await tester.tap(find.byKey(const Key('admin_logout')));
    await pump(tester, 3);
    expect(find.byKey(const Key('login_email')), findsOneWidget);

    // ---------------- SIGN UP: VOLUNTEER ----------------
    await tester.tap(find.byKey(const Key('login_signup_link')));
    await pump(tester);

    await tester.enterText(
      find.byKey(const Key('signup_name')),
      'QA Volunteer',
    );
    await tester.enterText(
      find.byKey(const Key('signup_email')),
      volunteerEmail,
    );
    await tester.enterText(
      find.byKey(const Key('signup_phone')),
      '+92-000-2222222',
    );
    // Role defaults to Field Volunteer, no need to change.
    await tester.enterText(find.byKey(const Key('signup_password')), password);
    await tester.enterText(
      find.byKey(const Key('signup_confirm')),
      password,
    );
    await tester.tap(find.byKey(const Key('signup_submit')));
    await pump(tester, 8);

    expect(find.text('Relief Dashboard'), findsWidgets);
    expect(find.text('User profile not found.'), findsNothing);
    expectNoVisibleError();

    // ---------------- SUBMIT REQUEST: EXISTING INVENTORY ITEM ----------------
    await tester.enterText(
      find.byKey(const Key('request_area')),
      'QA Test Area 1',
    );
    await tester.enterText(find.byKey(const Key('request_headcount')), '10');

    await tester.tap(find.byKey(const Key('item-0')));
    await pump(tester);
    // Pick a known seeded inventory item from the open dropdown menu.
    await tester.tap(find.text('Blankets').last);
    await pump(tester);

    await tester.tap(find.byKey(const Key('request_submit')));
    await pump(tester, 6);
    expect(find.textContaining('Request submitted successfully'), findsWidgets);

    // ---------------- SUBMIT REQUEST: CUSTOM ITEM ----------------
    await tester.enterText(
      find.byKey(const Key('request_area')),
      'QA Test Area 2',
    );
    await tester.enterText(find.byKey(const Key('request_headcount')), '5');

    await tester.tap(find.byKey(const Key('item-1')));
    await pump(tester);
    await tester.tap(find.text('Other (custom item)').last);
    await pump(tester);

    expect(find.byKey(const Key('custom-item-1')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('custom-item-1')),
      'QA Custom Item',
    );

    await tester.tap(find.byKey(const Key('request_submit')));
    await pump(tester, 6);
    expect(find.textContaining('Request submitted successfully'), findsWidgets);

    // ---------------- MY REQUESTS ----------------
    const volunteerNav = Key('volunteer_bottom_nav');
    await tapNavIcon(tester, volunteerNav, Icons.list_alt);
    await pump(tester, 3);
    expectNoVisibleError();
    expect(find.textContaining('QA Test Area 1'), findsOneWidget);
    expect(find.textContaining('QA Test Area 2'), findsOneWidget);

    await tapNavIcon(tester, volunteerNav, Icons.map_outlined);
    await pump(tester, 3);
    expectNoVisibleError();

    // ---------------- SIGN OUT ----------------
    await tester.tap(find.byKey(const Key('volunteer_logout')));
    await pump(tester, 3);
    expect(find.byKey(const Key('login_email')), findsOneWidget);

    // ---------------- LOG IN AS ADMIN, VERIFY ROUTING + ALLOCATE ----------------
    await tester.enterText(find.byKey(const Key('login_email')), adminEmail);
    await tester.enterText(
      find.byKey(const Key('login_password')),
      password,
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await pump(tester, 6);
    expect(find.text('Relief Coordinator'), findsOneWidget);

    await tapNavIcon(tester, adminNav, Icons.assignment_outlined);
    await pump(tester, 3);
    expectNoVisibleError();
    expect(find.textContaining('QA Test Area 1'), findsOneWidget);
    expect(find.textContaining('QA Test Area 2'), findsOneWidget);

    await tester.tap(find.text('Allocate Stock').first);
    await pump(tester, 3);
    expect(find.text('Allocate Stock'), findsWidgets);

    // Dismiss the modal bottom sheet by tapping the barrier above it.
    await tester.tapAt(const Offset(10, 10));
    await pump(tester, 2);

    // ---------------- FINAL SIGN OUT ----------------
    await tester.tap(find.byKey(const Key('admin_logout')));
    await pump(tester, 3);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
  });
}
