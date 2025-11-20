import 'package:cafe_well_doco/pages/splash_page.dart';
import 'package:cafe_well_doco/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'CoffeWellDoco Inventory',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(
          themeProvider.lightTheme.textTheme,
        ),
      ),
      darkTheme: themeProvider.darkTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(
          themeProvider.darkTheme.textTheme,
        ),
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashPage(),
    );
  }
}
