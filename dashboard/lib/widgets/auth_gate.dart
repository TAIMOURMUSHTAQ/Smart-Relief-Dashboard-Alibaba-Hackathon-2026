import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../screens/admin_home.dart';
import '../screens/login_screen.dart';
import '../screens/volunteer_home.dart';
import '../services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthGate build');
    final authService = context.watch<AuthService>();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        debugPrint('AuthGate streamBuilder: ${snapshot.connectionState}, user=${snapshot.data?.uid}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          debugPrint('AuthGate showing LoginScreen');
          return const LoginScreen();
        }

        return StreamBuilder<UserModel?>(
          stream: authService.userModelStream(user.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userModel = userSnap.data;
            if (userModel == null) {
              return const Scaffold(
                body: Center(child: Text('User profile not found.')),
              );
            }

            if (userModel.role == UserModel.roleAdmin) {
              return const AdminHome();
            }
            return const VolunteerHome();
          },
        );
      },
    );
  }
}
