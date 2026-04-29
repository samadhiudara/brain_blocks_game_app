import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Lock orientation before first frame ──────────────────────────────────
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // ── 2. Pre-load fonts OFF the main thread before runApp ─────────────────────
  //    This eliminates the "font download on first frame" jank completely.
  await Future.wait([
    GoogleFonts.pendingFonts([
      GoogleFonts.orbitron(),
      GoogleFonts.nunito(),
    ]),
  ]);

  // ── 3. Warm up SharedPreferences so the home screen never awaits it ─────────
  await SharedPreferences.getInstance();

  runApp(const BrainBlocksApp());
}

class BrainBlocksApp extends StatelessWidget {
  const BrainBlocksApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Build TextTheme once — reused everywhere, never recreated
    final textTheme = GoogleFonts.nunitoTextTheme(
      ThemeData.dark().textTheme,
    );

    return MaterialApp(
      title: 'BrainBlocks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: textTheme,
        scaffoldBackgroundColor: const Color(0xFF07071A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00D4FF),
          surface: Color(0xFF0D0D2B),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}