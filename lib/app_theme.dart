import 'package:flutter/material.dart';

/// Tema biru-putih untuk seluruh aplikasi.
/// Ubah warna di bagian atas ini kalau ingin biru yang lebih tua/muda.
class AppTheme {
  static const Color biru = Color(0xFF2F80ED);
  static const Color biruMuda = Color(0xFFE3EEFF);
  static const Color latar = Color(0xFFF3F8FF);
  static const Color garis = Color(0xFFD6E4FF);
  static const Color teksGelap = Color(0xFF0F2A4A);

  static ThemeData get light {
    final skema = ColorScheme.fromSeed(seedColor: biru).copyWith(
      primary: biru,
      onPrimary: Colors.white,
      primaryContainer: biruMuda,
      onPrimaryContainer: teksGelap,
      surface: Colors.white,
      onSurface: teksGelap,
      outline: garis,
      outlineVariant: garis,
    );

    final bentukInput = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: garis),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: skema,
      scaffoldBackgroundColor: latar,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: teksGelap,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: teksGelap,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        shape: Border(bottom: BorderSide(color: garis)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: garis),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: biru,
          side: const BorderSide(color: biru),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: bentukInput,
        enabledBorder: bentukInput,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: biru, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: biru,
        foregroundColor: Colors.white,
      ),
    );
  }
}
