import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api/dio_client.dart';
import 'package:dio/dio.dart'; // Import Dio for FormData and MultipartFile
import '../../../../models/mess.dart'; // Import Mess model for typing

class MessRepository {
  final DioClient _dio;
  MessRepository(this._dio);

  // *** MODIFIED: createMess to handle FormData and return Mess ***
  Future<Mess> createMess(Map<String, dynamic> data, XFile? imageFile) async {
    try {
      // *** FIX: Stringify complex fields for FormData ***
      final formDataMap = data.map((key, value) {
        // Stringify Maps and Lists before adding to FormData
        if (value is Map || value is List) {
          return MapEntry(key, jsonEncode(value)); // Encode nested structures
        }
        if (value is bool) {
          return MapEntry(key, value.toString()); // Keep boolean as string
        }
        // Convert other primitives to strings
        return MapEntry(key, value?.toString());
      });

      formDataMap.removeWhere((key, value) => value == null);

      final formData = FormData.fromMap(formDataMap);

      // Add image file if present
      if (imageFile != null) {
        formData.files.add(
          MapEntry(
            'messImage',
            MultipartFile.fromBytes(
              await imageFile.readAsBytes(),
              filename: imageFile.name,
            ),
          ),
        );
      }

      // Send the request - Dio sets Content-Type automatically for FormData
      final response = await _dio.post(
        '/mess',
        data: formData,
        // No need to explicitly set contentType: 'multipart/form-data' here,
        // Dio does it correctly when data is FormData.
      );

      // Check for successful creation status code
      if (response.statusCode == 201 && response.data != null) {
        // Ensure the 'data' key exists before accessing it
        if (response.data is Map && response.data.containsKey('data')) {
          return Mess.fromJson(response.data['data'] as Map<String, dynamic>);
        } else {
          // Handle unexpected successful response format
          throw 'Unexpected response format after creating mess.';
        }
      }

      // If status code is not 201, throw an error
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: response.data?['message'] ??
            'Failed to create mess (Status: ${response.statusCode})',
      );
    } on DioException catch (e) {
      // Extract backend error message if available, otherwise use Dio message
      final backendMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? e.response?.data['error'])
          : null;
      throw backendMessage ?? e.message ?? 'An unknown network error occurred';
    } catch (e) {
      // Catch any other unexpected errors (like image reading issues)
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  Future<Map<String, dynamic>> getMyMess() async {
    final res = await _dio.get('/mess/my-mess');
    return res.data;
  }

  Future<Map<String, dynamic>> updateMyMess(
      Map<String, dynamic> payload) async {
    final res = await _dio.put('/mess/my-mess', data: payload);
    return res.data;
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _dio.get('/mess/my-mess/dashboard');
    return res.data;
  }

  Future<Map<String, dynamic>> getMembersEatingNow() async {
    final res = await _dio.get('/mess/dashboard/members-eating');
    return res.data;
  }

  Future<Map<String, dynamic>> getMembersOnLeaveToday() async {
    final res = await _dio.get('/mess/dashboard/members-on-leave');
    return res.data;
  }

  Future<Map<String, dynamic>> getMembersSkippedCurrentMeal() async {
    final res = await _dio.get('/mess/dashboard/members-skipped');
    return res.data;
  }
}
