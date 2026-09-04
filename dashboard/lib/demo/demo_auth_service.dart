import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class DemoAuthService extends AuthService {
  final String role;

  DemoAuthService({required this.role});

  @override
  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  Stream<User?> get authStateChanges =>
      Stream.value(FirebaseAuth.instance.currentUser);

  @override
  Future<UserModel?> getUserModel(String uid) async {
    return UserModel(
      uid: 'demo-$role',
      name: role == UserModel.roleAdmin ? 'Demo Admin' : 'Demo Volunteer',
      role: role,
      phone: '+92-000-0000000',
    );
  }

  @override
  Stream<UserModel?> userModelStream(String uid) async* {
    yield await getUserModel(uid);
  }

  @override
  Future<UserCredential> signIn(String email, String password) async {
    throw UnsupportedError('Demo mode does not support sign-in');
  }

  @override
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
  }) async {
    throw UnsupportedError('Demo mode does not support sign-up');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> seedDemoAccounts() async {}
}
