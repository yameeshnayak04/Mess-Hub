import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  // Declares a global access point for the StorageService class instance.
  // This allows any part of the app to read/write secure data (like tokens) without needing to instantiate StorageService multiple times.
  return StorageService();
  // Creates a single, initialized instance of the StorageService class.
  // This ensures the app uses the same secure storage configuration everywhere.
});

class StorageService {
  // Defines the set of functions responsible for handling all secure storage operations.
  // Encapsulates storage logic in one place, separating data handling from UI code.

  // final: Variable assigned once.
  // _ (underscore prefix): Makes the variable private to this file/library.
  // FlutterSecureStorage: The object from the imported package.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
