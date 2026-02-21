import 'package:flutter/material.dart';

import '../constants.dart';

const InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
  fillColor: Colors.white, // Changed from lightGreyColor
  filled: true,
  hintStyle: TextStyle(color: Colors.grey),
  border: outlineInputBorder,
  enabledBorder: enabledOutlineInputBorder, // New enabled border
  focusedBorder: focusedOutlineInputBorder,
  errorBorder: errorOutlineInputBorder,
);

const InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
  fillColor: darkGreyColor,
  filled: true,
  hintStyle: TextStyle(color: whileColor40),
  border: outlineInputBorder,
  enabledBorder: enabledOutlineInputBorder, // New enabled border
  focusedBorder: focusedOutlineInputBorder,
  errorBorder: errorOutlineInputBorder,
);

// Updated default outline input border
const OutlineInputBorder outlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)), // Changed radius
  borderSide: BorderSide(
    color: Colors.grey, // Default border color
    width: 2, // Default border width
  ),
);

// New enabled outline input border
const OutlineInputBorder enabledOutlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
  borderSide: BorderSide(
    color: Colors.grey, // Enabled border color
    width: 2,
  ),
);

// Updated focused outline input border
const OutlineInputBorder focusedOutlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)), // Changed radius
  borderSide: BorderSide(color: kPrimaryColor, width: 2), // Changed color and width
);

const OutlineInputBorder errorOutlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)), // Changed radius
  borderSide: BorderSide(
    color: errorColor,
  ),
);

// This function can remain as it is, or be updated if needed for specific use cases
OutlineInputBorder secodaryOutlineInputBorder(BuildContext context) {
  return OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(12)), // Changed radius
    borderSide: BorderSide(
      color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.15),
    ),
  );
}
