import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:relief_dashboard/services/auth_service.dart';
import 'package:relief_dashboard/services/firestore_service.dart';
import 'package:relief_dashboard/theme/app_theme.dart';
import 'package:relief_dashboard/widgets/auth_gate.dart';

/// Builds a full app widget tree backed by fake Firebase services, so the
/// real screens and providers can be exercised without any network access
/// or a real device/emulator.
class TestHarness {
  TestHarness({FakeFirebaseFirestore? sharedFirestore})
    : firestore = sharedFirestore ?? FakeFirebaseFirestore(),
      auth = MockFirebaseAuth();

  final FakeFirebaseFirestore firestore;
  final MockFirebaseAuth auth;

  late final authService = AuthService(auth: auth, firestore: firestore);
  late final firestoreService = FirestoreService(firestore: firestore);

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<FirestoreService>.value(
          value: firestoreService,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}
