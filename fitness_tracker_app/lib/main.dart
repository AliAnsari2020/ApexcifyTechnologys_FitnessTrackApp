import 'package:fitness_tracker_app/Welcome_Screen/OnboardingScreen%20.dart';
import 'package:fitness_tracker_app/Welcome_Screen/Signup.dart';
import 'package:fitness_tracker_app/Welcome_Screen/WelcomeScreen.dart';
import 'package:fitness_tracker_app/Welcome_Screen/login.dart';
import 'package:fitness_tracker_app/Welcome_Screen/splash.dart';
import 'package:fitness_tracker_app/pages/DashboardPage.dart';
import 'package:fitness_tracker_app/pages/add_activity_page.dart';
import 'package:fitness_tracker_app/pages/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Fitness Tracker",
      theme: ThemeData(primarySwatch: Colors.teal, fontFamily: 'Roboto'),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/add-activity': (context) => const AddActivityPage(),
        '/statistics': (context) => const StatisticsPage(),
      },
    );
  }
}
