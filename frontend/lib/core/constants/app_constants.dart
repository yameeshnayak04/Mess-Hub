// This file centralizes constants used throughout the UI for consistency.

import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._(); // Private constructor

  // --- COLORS ---
  // Define your primary app colors here.
  static const Color primaryColor = Colors.deepOrange;
  static const Color accentColor = Color(0xFFFFA726); // A lighter orange
  static const Color backgroundColor =
      Color(0xFFF5F5F5); // Light grey background
  static const Color textColor = Color(0xFF333333); // Dark grey for text

  // --- PADDING & MARGINS ---
  // Define standard padding values to use across different screens.
  static const double pagePadding = 24.0;
  static const double widgetSpacing = 20.0;

  // --- BORDER RADIUS ---
  // Define standard border radius for cards, buttons, etc.
  static const double borderRadius = 8.0;
}
