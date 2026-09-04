import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'demo/demo_auth_service.dart';
import 'demo/demo_firestore_service.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/volunteer_home.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'volunteer@relief.demo',
      password: 'demo123456',
    );
  } catch (e) {
    debugPrint('Demo volunteer sign-in skipped: $e');
  }
  runApp(const DemoVolunteerApp());
}

class DemoVolunteerApp extends StatelessWidget {
  const DemoVolunteerApp({super.key});

  int get _tabIndex {
    final uri = Uri.base;
    switch (uri.queryParameters['tab']) {
      case 'requests':
        return 1;
      case 'map':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => DemoAuthService(role: UserModel.roleVolunteer),
        ),
        ChangeNotifierProvider<FirestoreService>(
          create: (_) => DemoFirestoreService(),
        ),
      ],
      child: MaterialApp(
        title: 'Relief Dashboard — Volunteer Demo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: VolunteerHome(initialIndex: _tabIndex),
      ),
    );
  }
}
