// Colours, fonts and shared styles.
// The look: blue ballpoint ink on white paper, a yellow highlighter
// for anything that matches, and a red pen for things to fix.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color desk = Color(0xFFF1F4FA); // screen background
  static const Color sheet = Color(0xFFFFFFFF); // paper
  static const Color ink = Color(0xFF16245C); // ballpoint blue
  static const Color text = Color(0xFF2B3452);
  static const Color muted = Color(0xFF68718F);
  static const Color line = Color(0xFFD9DFEC);
  static const Color track = Color(0xFFE6EAF3);
  static const Color marker = Color(0xFFFFE45C); // highlighter
  static const Color markerEdge = Color(0xFFE9C600);
  static const Color markerSoft = Color(0xFFFFF7CC);
  static const Color redPen = Color(0xFFD23B30);
  static const Color tick = Color(0xFF1B8553);
  static const Color shadow = Color(0x1416245C);
}

/// Text styles. T.display for headings, T.body for everything else,
/// T.pen for handwritten red pen notes.
class T {
  static TextStyle display(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w700,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.14,
      letterSpacing: -0.3,
    );
  }

  static TextStyle body(
    double size, {
    Color color = AppColors.text,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.hankenGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.45,
    );
  }

  static TextStyle pen(double size) {
    return GoogleFonts.caveat(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: AppColors.redPen,
      height: 1.15,
    );
  }
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.ink).copyWith(
    primary: AppColors.ink,
    onPrimary: Colors.white,
    surface: AppColors.desk,
    onSurface: AppColors.text,
    error: AppColors.redPen,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.desk,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.hankenGrotesk().fontFamily,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.sheet,
      indicatorColor: AppColors.marker,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
    ),
  );
}

/// The same look for every text box in the app.
InputDecoration fieldDecoration({String? label, String? hint}) {
  OutlineInputBorder border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: AppColors.sheet,
    alignLabelWithHint: true,
    hintStyle: T.body(15, color: AppColors.muted),
    labelStyle: T.body(15, color: AppColors.muted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(AppColors.line, 1),
    enabledBorder: border(AppColors.line, 1),
    focusedBorder: border(AppColors.ink, 1.6),
  );
}

/// The same top bar for every screen that has one.
PreferredSizeWidget plainAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    title: Text(title, style: T.display(19)),
    backgroundColor: AppColors.desk,
    foregroundColor: AppColors.ink,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    actions: actions,
  );
}
