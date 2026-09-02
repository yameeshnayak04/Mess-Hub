// lib/features/manager/create_mess/repositories/mess_repository.dart
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../models/mess.dart';
import '../../../../models/dashboard_stats.dart';

/// What came back from creating a mess.
///
/// The picture is uploaded as a second request, so it can fail on its own
/// without the mess failing - hence two fields rather than just an id.
class MessCreationResult {
  final String messId;
  final bool pictureUploaded;

  const MessCreationResult({
    required this.messId,
    required this.pictureUploaded,
  });
}

class MessRepository {
  final DioClient _dio;
  MessRepository(this._dio);

  /// Creates the mess together with its plans in one call.
  ///
  /// `data` must already be in the backend's shape (see createMessSchema):
  /// flat `lunchStart`/`lunchEnd`/`dinnerStart`/`dinnerEnd`, a
  /// `location: { longitude, latitude }` object, `*Rupees` money fields, and
  /// `plans: [{ name, rateRupees, meals }]`.
  ///
  /// Returns the new mess id. The create response is `{ messId, plans }`
  /// rather than a whole mess, so callers fetch the mess afterwards if they
  /// need it.
  ///
  /// The picture, if there is one, is uploaded straight after as its own
  /// request - see [_uploadMessImage] for why it cannot ride along with this
  /// one.
  Future<MessCreationResult> createMess(
    Map<String, dynamic> data,
    XFile? imageFile,
  ) async {
    final String messId;
    try {
      final res = await _dio.post('/messes', data: data);
      final result = Map<String, dynamic>.from(DioClient.unwrap(res) as Map);
      messId = result['messId'].toString();
    } catch (error) {
      throw DioClient.asApiException(error);
    }

    if (imageFile == null) {
      return MessCreationResult(messId: messId, pictureUploaded: false);
    }

    // The mess exists by this point. If the picture fails - it goes to a third
    // party image host, which can time out - reporting "creating the mess
    // failed" would be a lie, and a retry would then hit a duplicate-mess
    // error. So the picture is best-effort; the manager can set one later from
    // the mess profile.
    try {
      await _uploadMessImage(
        bytes: await imageFile.readAsBytes(),
        filename: imageFile.name,
        messName: data['messName'] as String,
      );
      return MessCreationResult(messId: messId, pictureUploaded: true);
    } catch (_) {
      return MessCreationResult(messId: messId, pictureUploaded: false);
    }
  }

  /// Sends just the picture, as a second request.
  ///
  /// A file has to travel as multipart, and in a multipart body every field
  /// arrives at the server as a string - so `location`, `rules` and `plans`
  /// would show up as text where the API wants an object, an object and an
  /// array. Nothing on the server unpacks them again, so an image can never
  /// share a request with those fields.
  ///
  /// `messName` rides along unchanged because the update route rejects a body
  /// with no fields in it at all; the file alone does not count as one.
  Future<void> _uploadMessImage({
    required List<int> bytes,
    required String filename,
    required String messName,
  }) async {
    final form = FormData.fromMap({'messName': messName});
    form.files.add(MapEntry(
      'messImage',
      MultipartFile.fromBytes(bytes, filename: filename),
    ));

    DioClient.unwrap(await _dio.patch('/messes/my-mess', data: form));
  }

  Future<Mess> getMyMess() async {
    try {
      final res = await _dio.get('/messes/my-mess');
      return Mess.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// PATCH now - the backend applies a partial update, so send only what
  /// actually changed.
  Future<Mess> updateMyMess(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/messes/my-mess', data: payload);
      return Mess.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<DashboardStats> getDashboard({String? meal}) async {
    try {
      final res = await _dio.get(
        '/messes/my-mess/dashboard',
        queryParameters: {if (meal != null) 'meal': meal},
      );
      return DashboardStats.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// The four separate "members eating / on leave / skipped" endpoints have
  /// collapsed into one filtered route, which also supports 'Absent' and
  /// 'Remaining'.
  Future<List<DashboardMember>> getMembersByStatus(
    String status, {
    String? meal,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final res = await _dio.get(
        '/messes/my-mess/dashboard/members',
        queryParameters: {
          'status': status,
          if (meal != null) 'meal': meal,
          'page': page,
          'limit': limit,
        },
      );
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => DashboardMember.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<List<DashboardMember>> getMembersEatingNow({String? meal}) =>
      getMembersByStatus('Present', meal: meal);

  Future<List<DashboardMember>> getMembersOnLeaveToday({String? meal}) =>
      getMembersByStatus('Leave', meal: meal);

  Future<List<DashboardMember>> getMembersSkippedCurrentMeal({String? meal}) =>
      getMembersByStatus('Skipped', meal: meal);

  /// New capability: who is still expected but has not turned up yet.
  Future<List<DashboardMember>> getMembersRemaining({String? meal}) =>
      getMembersByStatus('Remaining', meal: meal);
}
