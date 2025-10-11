// This is the main entry point for the Flutter application.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/auth/presentation/screens/register_screen.dart'; // We will create this screen next

void main() {
  DioClient.instance.setupInterceptors();
  // The ProviderScope is a widget that stores the state of all our providers.
  // It's essential for Riverpod to work.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mess Hub',
      // We define a consistent and modern theme for the entire app here.
      theme: ThemeData(
        // Use Material 3 design for modern components.
        useMaterial3: true,
        // Define the primary color swatch.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
        // Define a consistent style for all input fields.
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        // Define a consistent style for all elevated buttons.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange, // Button color
            foregroundColor: Colors.white, // Text color
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // The first screen the user will see.
      home: const RegisterScreen(),
    );
  }
}
