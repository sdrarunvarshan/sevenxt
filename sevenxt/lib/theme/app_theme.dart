import 'package:flutter/material.dart';
import 'package:sevenxt/theme/button_theme.dart';
import 'package:sevenxt/theme/input_decoration_theme.dart';

import '../constants.dart';
import 'checkbox_themedata.dart';
import 'theme_data.dart';

class AppTheme {
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: "poppins",
      primarySwatch: kPrimaryMaterialColor,
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: Colors.white,

      colorScheme: const ColorScheme.light(
        primary: kPrimaryColor,
        secondary: kPrimaryColor,
        surface: kSurfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: blackColor,
        onError: Colors.white,
      ),

      iconTheme: const IconThemeData(color: blackColor),

      textTheme: _textTheme,

      elevatedButtonTheme: elevatedButtonThemeData,
      textButtonTheme: textButtonThemeData,
      outlinedButtonTheme: outlinedButtonTheme(),

      inputDecorationTheme: lightInputDecorationTheme,

      checkboxTheme: checkboxThemeData.copyWith(
        side: const BorderSide(color: blackColor40),
      ),

      // ✅ FIXED: Removed duplicate appBarTheme above
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: blackColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: blackColor),
        titleTextStyle: TextStyle(
          color: blackColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: "poppins",
        ),
      ),

      scrollbarTheme: scrollbarThemeData,
      dataTableTheme: dataTableLightThemeData,

      // ✅ Card Theme with visible border
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadious),
          side: const BorderSide(color: blackColor20, width: 1),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: blackColor40,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      dividerTheme: const DividerThemeData(
        color: blackColor10,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: blackColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: "poppins",
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Comprehensive Text Theme
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: "poppins",
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: blackColor,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontFamily: "poppins",
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: blackColor,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontFamily: "poppins",
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: blackColor,
    ),
    headlineLarge: TextStyle(
      fontFamily: "poppins",
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: blackColor,
    ),
    headlineMedium: TextStyle(
      fontFamily: "poppins",
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: blackColor,
    ),
    headlineSmall: TextStyle(
      fontFamily: "poppins",
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: blackColor,
    ),
    titleLarge: TextStyle(
      fontFamily: "poppins",
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: blackColor,
    ),
    titleMedium: TextStyle(
      fontFamily: "poppins",
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: blackColor,
    ),
    titleSmall: TextStyle(
      fontFamily: "poppins",
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: blackColor,
    ),
    bodyLarge: TextStyle(
      fontFamily: "poppins",
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: blackColor,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: "poppins",
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: blackColor80,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: "poppins",
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: blackColor40,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontFamily: "poppins",
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: blackColor,
      letterSpacing: 0.5,
    ),
    labelMedium: TextStyle(
      fontFamily: "poppins",
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: blackColor60,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontFamily: "poppins",
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: blackColor40,
      letterSpacing: 0.5,
    ),
  );
}
