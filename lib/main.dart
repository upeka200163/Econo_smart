import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:econosmart/providers/api_provider.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ApiProvider(),
      child: const EconoSmartApp(),
    ),
  );
}

class EconoSmartApp extends StatelessWidget {
  const EconoSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EconoSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A6B6B)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
