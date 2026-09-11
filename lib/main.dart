import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'logic/auth_provider.dart';
import 'ui/widgets/shake_detector_wrapper.dart';

import 'ui/screens/login_screen.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/leaderboard_screen.dart';
import 'ui/screens/admin_screen.dart';
import 'ui/screens/rules_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: FantaDanieleApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminScreen(),
    ),
    GoRoute(
      path: '/rules',
      builder: (context, state) => const RulesScreen(),
    ),
  ],
);

class FantaDanieleApp extends StatelessWidget {
  const FantaDanieleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FantaDaniele',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5BB5)),
        useMaterial3: true,
      ),
      routerConfig: _router,
      builder: (context, child) {
        return ShakeDetectorWrapper(child: child!);
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
