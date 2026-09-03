import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const background = Color(0xFFF2F2F0);
  static const ink = Color(0xFF111111);
  static const yellow = Color(0xFFFFD200);
  static const pink = Color(0xFFEC1E79);
  static const blue = Color(0xFF1E88E5);
  static const red = Color(0xFFE53935);
  static const darkBackground = Color(0xFF121212);

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? darkBackground : background;
    final surface = isDark ? const Color(0xFF242424) : Colors.white;
    final onSurface = isDark ? Colors.white : ink;
    final secondaryText = isDark
        ? const Color(0xFFDDDDDD)
        : const Color(0xFF4D4D4D);
    final bodyTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: onSurface, displayColor: onSurface);
    TextStyle? display(TextStyle? style) => GoogleFonts.bangers(
      textStyle: style,
      color: onSurface,
      letterSpacing: 1.4,
    );
    final textTheme = bodyTheme.copyWith(
      headlineLarge: display(bodyTheme.headlineLarge),
      headlineMedium: display(bodyTheme.headlineMedium),
      headlineSmall: display(bodyTheme.headlineSmall),
      titleLarge: display(bodyTheme.titleLarge),
      titleMedium: bodyTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
      titleSmall: bodyTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      bodyMedium: bodyTheme.bodyMedium?.copyWith(color: secondaryText),
      bodySmall: bodyTheme.bodySmall?.copyWith(color: secondaryText),
      labelLarge: bodyTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
      labelMedium: bodyTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
    );
    final scheme = ColorScheme(
      brightness: brightness,
      primary: blue,
      onPrimary: Colors.white,
      secondary: pink,
      onSecondary: Colors.white,
      error: red,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
    );
    final boxyShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: const BorderSide(color: ink, width: 2.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      dividerColor: ink,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: canvas,
        foregroundColor: onSurface,
        titleTextStyle: display(bodyTheme.headlineSmall),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 5,
        shadowColor: ink,
        color: surface,
        margin: EdgeInsets.zero,
        shape: boxyShape,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 5,
          shadowColor: ink,
          backgroundColor: blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: boxyShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 5,
          shadowColor: ink,
          backgroundColor: pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: boxyShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 4,
          shadowColor: ink,
          foregroundColor: ink,
          backgroundColor: yellow,
          side: const BorderSide(color: ink, width: 2.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? yellow : ink,
          textStyle: textTheme.labelLarge?.copyWith(
            decoration: TextDecoration.underline,
            decorationThickness: 2,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 6,
        backgroundColor: pink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          side: BorderSide(color: ink, width: 2.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? ink : Colors.white,
        selectedItemColor: isDark ? Colors.white : ink,
        unselectedItemColor: isDark ? Colors.white70 : ink,
        selectedLabelStyle: textTheme.labelMedium,
        unselectedLabelStyle: textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w800),
        hintStyle: TextStyle(color: secondaryText),
        prefixIconColor: onSurface,
        suffixIconColor: onSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: ink, width: 2.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: ink, width: 2.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: blue, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: red, width: 3),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF353535) : Colors.white,
        selectedColor: yellow,
        side: const BorderSide(color: ink, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        labelStyle: textTheme.labelMedium?.copyWith(color: ink),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: pink,
        circularTrackColor: Color(0x33EC1E79),
        linearTrackColor: Color(0x33EC1E79),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurface,
        textColor: onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? blue : surface,
        ),
        side: const BorderSide(color: ink, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? ink : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? yellow : Colors.grey,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(ink),
      ),
    );
  }
}
