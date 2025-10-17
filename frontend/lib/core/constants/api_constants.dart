// This file centralizes all API-related constants for easy management.

class ApiConstants {
  // The private constructor prevents anyone from creating an instance of this class.
  ApiConstants._();

  // This is the base URL for your backend server.
  //
  // IMPORTANT:
  // When running the app on an Android Emulator, 'localhost' or '127.0.0.1'
  // refers to the emulator's own internal network, NOT your computer.
  //
  // To connect to the 'localhost' of your computer from the Android Emulator,
  // you MUST use the special alias '10.0.2.2'.
  static const String baseUrl = "http://10.121.118.41:3000/api";
}
