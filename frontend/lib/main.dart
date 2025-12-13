import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // Glue between flutter engine and widgets
  WidgetsFlutterBinding
      .ensureInitialized(); // System Settings should be modified before flutter starts rendering the UI

  // Set system UI overlay style (Configure's appearance of system UI elements)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock to portrait mode (Only up and down portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    // The core flutter function that inflates the given widget and attaches it to screen (renders the app UI)
    // Manages the state and dependencies for the entire app
    // Centralizes state management, making data flow predictable and efficient throughout the application.
    const ProviderScope(
      // It is a widget provided by riverpod used to wrap Main Application Widget
      child: MessManagementApp(),
    ),
  );
}

class MessManagementApp extends ConsumerWidget {
  // A special type of widget which can read or watch state data
  // Defines the core UI component (Widget) of your application that can interact with the app's state.
  const MessManagementApp({super.key});
  // The constructor ensures the widget can be instantiated correctly with an optional key for widget identification.

  @override
  // The required method that describes the UI represented by this widget. It returns a widget subtree.
  Widget build(BuildContext context, WidgetRef ref) {
    // BuildContext: A handle to the location of a widget in the widget tree.
    // WidgetRef: An object provided by Riverpod to interact with application state (e.g., watch providers).
    // It uses the ref to fetch the current navigation configuration and uses the context to determine where in the UI tree it sits.

    final router = ref.watch(appRouterProvider);
    // ref.watch(): A Riverpod method to "listen" to a provider.
    // Links the main app UI setup to the navigation logic, so if the routes change, the main app rebuilds automatically.

    return MaterialApp.router(
      // return: Exits the current function and provides a value.
      // MaterialApp: A convenience widget that wraps a number of widgets that are commonly required for Material Design applications.

      title: 'Mess Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      // This is where the app learns which screen to show based on the current URL path or navigation stack.
    );
  }
}
