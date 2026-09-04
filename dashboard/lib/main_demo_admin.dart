import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'demo/demo_auth_service.dart';
import 'demo/demo_firestore_service.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/admin_home.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'admin@relief.demo',
      password: 'demo123456',
    );
  } catch (e) {
    debugPrint('Demo admin sign-in skipped: $e');
  }
  runApp(const DemoAdminApp());
}

class DemoAdminApp extends StatelessWidget {
  const DemoAdminApp({super.key});

  int get _tabIndex {
    final uri = Uri.base;
    switch (uri.queryParameters['tab']) {
      case 'requests':
        return 1;
      case 'inventory':
        return 2;
      case 'map':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => DemoAuthService(role: UserModel.roleAdmin),
        ),
        ChangeNotifierProvider<FirestoreService>(
          create: (_) => DemoFirestoreService(),
        ),
      ],
      child: MaterialApp(
        title: 'Relief Dashboard — Admin Demo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: AdminHome(initialIndex: _tabIndex),
      ),
    );
  }
}
