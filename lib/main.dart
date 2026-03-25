import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sexpedition_application_1/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const eroticBackground = Color(0xFF13070D);
    const eroticSurface = Color(0xFF22101A);
    const eroticPrimary = Color(0xFFE83E8C);
    const eroticSecondary = Color(0xFFFF6B9E);
    const eroticOnDark = Color(0xFFF8EAF1);

    final scheme = const ColorScheme.dark(
      primary: eroticPrimary,
      secondary: eroticSecondary,
      surface: eroticSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: eroticOnDark,
      error: Color(0xFFFF6B6B),
      onError: Colors.white,
    );

    return MaterialApp(
      title: 'Секс-календарь',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: eroticBackground,
        cardTheme: const CardThemeData(
          color: eroticSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: eroticBackground,
          foregroundColor: eroticOnDark,
          centerTitle: true,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: eroticSurface,
          indicatorColor: eroticPrimary.withValues(alpha: 0.24),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: eroticPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        chipTheme: ChipThemeData.fromDefaults(
          secondaryColor: eroticPrimary,
          brightness: Brightness.dark,
          labelStyle: const TextStyle(color: eroticOnDark),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: const App(),
    );
  }
}
