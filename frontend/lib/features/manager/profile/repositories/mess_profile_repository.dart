// lib/features/manager/profile/repositories/mess_profile_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../models/mess.dart';

class MessProfileRepository {
  final DioClient _dio;
  MessProfileRepository(this._dio);

  Future<Mess> getMyMess() async {
    try {
      final res = await _dio.get('/messes/my-mess');
      return Mess.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Fields the mess-profile screen may change.
  ///
  /// Timings are four flat keys now, not a nested lunch/dinner object, and the
  /// money fields carry the `Rupees` suffix. Plans are NOT edited here any
  /// more - they have their own endpoints (see [addPlan] / [updatePlan] /
  /// [retirePlan]).
  static const _editableKeys = <String>{
    'messName',
    'address',
    'city',
    'contactPhone',
    'maxCapacity',
    'tiffinService',
    'basicThaliDetails',
    'serviceType',
    'cuisine',
    'lunchStart',
    'lunchEnd',
    'dinnerStart',
    'dinnerEnd',
    'dailyThaliRateRupees',
    'rules',
  };

  Future<Mess> updateMyMess({
    required Map<String, dynamic> fields,
    MultipartFile? imageFile,
  }) async {
    final filtered = <String, dynamic>{};
    fields.forEach((key, value) {
      if (_editableKeys.contains(key)) filtered[key] = value;
    });

    try {
      // JSON for the fields, so numbers stay numbers and `rules` stays an
      // object. Joi strips unknown keys, so anything not editable is simply
      // ignored rather than rejected.
      Mess? updated;
      if (filtered.isNotEmpty) {
        final res = await _dio.patch('/messes/my-mess', data: filtered);
        updated = Mess.fromJson(
            Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
      }

      // The picture goes on its own, because a multipart body turns every
      // field into a string and nothing on the server turns `rules` back into
      // an object. `messName` rides along unchanged only because the route
      // rejects a body with no fields at all - the file does not count as one.
      if (imageFile != null) {
        final form = FormData.fromMap({
          'messName': updated?.messName ?? (await getMyMess()).messName,
        });
        form.files.add(MapEntry('messImage', imageFile));

        final res = await _dio.patch('/messes/my-mess', data: form);
        updated = Mess.fromJson(
            Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
      }

      return updated ?? await getMyMess();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  // ------------------------------------------------------------------ plans

  Future<List<MessPlan>> getPlans() async {
    try {
      final res = await _dio.get('/messes/my-mess/plans');
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => MessPlan.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<MessPlan> addPlan({
    required String name,
    required double rateRupees,
    required List<String> meals,
  }) async {
    try {
      final res = await _dio.post('/messes/my-mess/plans', data: {
        'name': name,
        'rateRupees': rateRupees,
        'meals': meals,
      });
      return MessPlan.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Changing a plan's rate affects EVERY active member on it, from their next
  /// bill onwards - the backend reads the rate live rather than storing a copy
  /// on each membership. The UI must say so before saving.
  Future<MessPlan> updatePlan({
    required String planId,
    required String name,
    required double rateRupees,
    required List<String> meals,
  }) async {
    try {
      final res = await _dio.patch('/messes/my-mess/plans/$planId', data: {
        'name': name,
        'rateRupees': rateRupees,
        'meals': meals,
      });
      return MessPlan.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Plans are retired, never deleted - memberships point at them. The backend
  /// refuses while anyone is still on the plan.
  Future<void> retirePlan(String planId) async {
    try {
      DioClient.unwrap(await _dio.delete('/messes/my-mess/plans/$planId'));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
