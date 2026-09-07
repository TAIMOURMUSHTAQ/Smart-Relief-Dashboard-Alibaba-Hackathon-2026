import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson(doc.id, doc.data()!);
  }

  Stream<UserModel?> userModelStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) =>
              doc.exists && doc.data() != null
              ? UserModel.fromJson(doc.id, doc.data()!)
              : null,
        );
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (credential.user != null) {
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name.trim(),
        'role': role,
        'phone': phone.trim(),
      });
    }

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> seedDemoAccounts() async {
    final accounts = [
      {'email': 'admin@relief.demo', 'password': 'demo123456', 'role': 'admin'},
      {
        'email': 'volunteer@relief.demo',
        'password': 'demo123456',
        'role': 'volunteer',
      },
    ];

    for (final account in accounts) {
      try {
        final email = account['email']!;
        final password = account['password']!;
        final role = account['role']!;

        UserCredential cred;
        try {
          cred = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'invalid-credential' ||
              e.code == 'user-not-found' ||
              e.code == 'wrong-password') {
            cred = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } else {
            rethrow;
          }
        }

        final profile = await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .get();
        if (!profile.exists) {
          await _firestore.collection('users').doc(cred.user!.uid).set({
            'name': role == 'admin' ? 'Demo Admin' : 'Demo Volunteer',
            'role': role,
            'phone': '+92-000-0000000',
          });
        }
      } catch (e) {
        debugPrint('Seed account error: $e');
      }
    }
  }
}
