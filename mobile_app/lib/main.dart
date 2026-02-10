import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState())],
      child: const TransportApp(),
    ),
  );
}

class TransportApp extends StatelessWidget {
  const TransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp(
      title: 'Transport Scheduler',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
      ),
      home: const HomeScreen(),
    );
  }
}
