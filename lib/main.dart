import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/request_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SkillBridgeApp());
}

class SkillBridgeApp extends StatelessWidget {
  const SkillBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ MultiProvider is now INSIDE MaterialApp's builder
    // This ensures all pushed routes get the providers on web
    return MaterialApp(
      title: 'Skill Bridge',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      builder: (context, child) {
        // ✅ Wrap the entire navigator with MultiProvider
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => SkillProvider()),
            ChangeNotifierProvider(create: (_) => RequestProvider()),
          ],
          child: child!,
        );
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
      home: const LoginScreen(),
    );
  }
}