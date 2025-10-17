// This is the main entry point for the Flutter application.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/core/api/dio_client.dart'; // Import DioClient
import 'package:mess_management_system/core/routing/app_router.dart'; // Import your AppRouter
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

Future<void> main() async {
  // <-- Make main async
  // --- ADD THIS BLOCK ---
  // Load the .env file
  await dotenv.load(fileName: ".env");
  // ---------------------

  DioClient.instance.setupInterceptors();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mess Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ... (your existing theme data remains the same)
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
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

      // --- THIS IS THE CRITICAL FIX ---
      // 'onGenerateRoute' tells MaterialApp to use our AppRouter to handle all named navigations.
      // Whenever Navigator.pushNamed is called, this function will run.
      onGenerateRoute: AppRouter.generateRoute,

      // 'initialRoute' sets the first screen that the app will show.
      // We use the constant from our AppRouter to avoid typos.
      initialRoute: AppRouter.loginRoute,
      // ------------------------------------
    );
  }
}
