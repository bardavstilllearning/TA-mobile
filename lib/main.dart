import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'views/splash_screen.dart';
import 'services/notification_service.dart';
import 'utils/user_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await UserPreferences.initializeDefaults();
  runApp(const KerahBiruApp());
}

class KerahBiruApp extends StatelessWidget {
  const KerahBiruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KerahBiru',
      debugShowCheckedModeBanner: false,

      // set up defaultnya ke lokal (Indonesia)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      locale: const Locale('id', 'ID'),

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A73FF)),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
    );
  }
}
