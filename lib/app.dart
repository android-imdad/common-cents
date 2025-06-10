import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main_screen.dart';


class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    var offWhite = const Color(0xFFe8e8e8);
    // Using Lato font, apply globally
    final textTheme = GoogleFonts.latoTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: GoogleFonts.lato(fontSize: 18.0, color: offWhite),
      bodyMedium: GoogleFonts.lato(fontSize: 16.0, color: offWhite),
      headlineMedium: GoogleFonts.lato(fontSize: 28.0, fontWeight: FontWeight.bold, color: offWhite),
      headlineSmall: GoogleFonts.lato(fontSize: 24.0, fontWeight: FontWeight.bold, color: offWhite),
      titleLarge: GoogleFonts.lato(fontSize: 22.0, fontWeight: FontWeight.bold, color: offWhite),
      labelLarge: GoogleFonts.lato(fontSize: 18.0, fontWeight: FontWeight.bold, color: offWhite),
    );

    return MaterialApp(
      title: 'Budget Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: textTheme.titleLarge,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.tealAccent,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: GoogleFonts.lato(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.lato(),
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.tealAccent,
          foregroundColor: Colors.black,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme( // Theme for TextField in Dialog
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixStyle: const TextStyle(color: Colors.white, fontSize: 18),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.tealAccent),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent, width: 2),
          ),
        ), // Theme for AlertDialog
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titleTextStyle: textTheme.titleLarge,
          backgroundColor: Colors.grey[900]
        ),
        textButtonTheme: TextButtonThemeData( // Theme for Dialog buttons
          style: TextButton.styleFrom(
            foregroundColor: Colors.tealAccent,
            textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
        ),
        snackBarTheme: SnackBarThemeData( // Theme for Snackbars
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
      ),
      home: const MainScreen(),
    );
  }
}