import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'demo/demo_auth_service.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/signup_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SignupDemoApp());
}

class SignupDemoApp extends StatelessWidget {
  const SignupDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthService>(
      create: (_) => DemoAuthService(role: UserModel.roleVolunteer),
      child: MaterialApp(
        title: 'Relief Dashboard — Sign Up',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SignupScreen(),
      ),
    );
  }
}
