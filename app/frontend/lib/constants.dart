import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

// Just for demo
const productDemoImg1 = "https://i.imgur.com/vQXS6ph.jpeg";
const productDemoImg2 = "https://i.imgur.com/AkzWQuJ.png";
const productDemoImg3 = "https://i.imgur.com/J7mGZ12.png";
const productDemoImg4 = "https://i.imgur.com/oZu0Zrg.png";
const productDemoImg5 = "https://i.imgur.com/icssR2z.jpeg";
const productDemoImg6 = "https://i.imgur.com/XlCiFjw.jpeg";

// End For demo
const grandisExtendedFont = "poppins-extrabold";

// 1. CONSTANTS & THEME
// -----------------------------------------------------------------------------

const Color kPrimaryColor = Color(0xFFEF4444); // Red-500
const Color kPrimaryDark = Color(0xFFDC2626); // Red-600
const Color kBackgroundColor = Color(0xFFFFFFFF);
const Color kSurfaceColor = Color(0xFFF3F4F6); // Gray-100
const double kBorderRadius = 16.0;

// On color 80, 60.... those means opacity

const MaterialColor kPrimaryMaterialColor =
    MaterialColor(0xFFEF4444, <int, Color>{
  50: Color(0xFFFFF5F5), // Red-50
  100: Color(0xFFFFEEEE), // Red-100
  200: Color(0xFFFECACA), // Red-200
  300: Color(0xFFFCA5A5), // Red-300
  400: Color(0xFFF87171), // Red-400
  500: Color(0xFFEF4444), // Red-500
  600: Color(0xFFDC2626), // Red-600
  700: Color(0xFFB91C1C), // Red-700
  800: Color(0xFF991B1B), // Red-800
  900: Color(0xFF7F1D1D), // Red-900
});

const Color blackColor = Color(0xFF16161E);
const Color blackColor80 = Color(0xFF45454B);
const Color blackColor60 = Color(0xFF737378);
const Color blackColor40 = Color(0xFFA2A2A5);
const Color blackColor20 = Color(0xFFD0D0D2);
const Color blackColor10 = Color(0xFFE8E8E9);
const Color blackColor5 = Color(0xFFF3F3F4);

const Color whiteColor = kBackgroundColor;
const Color whileColor80 = Color(0xFFCCCCCC);
const Color whileColor60 = Color(0xFF999999);
const Color whileColor40 = Color(0xFF666666);
const Color whileColor20 = Color(0xFF333333);
const Color whileColor10 = Color(0xFF191919);
const Color whileColor5 = Color(0xFF0D0D0D);


const Color greyColor = Color(0xFFB8B5C3);
const Color lightGreyColor = Color(0xFFF0F0F0);
const Color darkGreyColor = Color(0xFF1C1C25);

const Color secondaryColor = kPrimaryColor; // Replaced purpleColor
const Color successColor = Color(0xFF2ED573);
const Color warningColor = Color(0xFFFFBE21);
const Color errorColor = Color(0xFFEA5B5B);

const double defaultPadding = 16.0;
const double defaultBorderRadious = kBorderRadius;
const Duration defaultDuration = Duration(milliseconds: 300);

final passwordValidator = MultiValidator([
  RequiredValidator(errorText: 'Password is required'),
  MinLengthValidator(8, errorText: 'password must be at least 8 digits long'),
  PatternValidator(r'(?=.*?[#?!@$%^&*-])',
      errorText: 'passwords must have at least one special character')
]);

final emaildValidator = MultiValidator([
  RequiredValidator(errorText: 'Email is required'),
  EmailValidator(errorText: "Enter a valid email address"),
]);

const pasNotMatchErrorText = "passwords do not match";
