// lib/features/manager/create_mess/providers/create_mess_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:mess_management_app/features/auth/providers/auth_provider.dart';
import '../../../../models/user.dart'; // Import Location model
import '../repositories/mess_repository.dart'; // Import MessRepository
import '../../../../core/api/dio_client_provider.dart'; // Import dioClientProvider

// Provider for the repository
final messRepositoryProvider = Provider<MessRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return MessRepository(dioClient);
});

// State definition
class CreateMessState {
  final int currentStep;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic> formData;
  // *** FIX: Change type to XFile? ***
  final XFile? messImage;
  final bool isSubmitting;

  /// The mess was created but its picture did not upload. Not an error - the
  /// mess is real and usable - just something to tell the manager about.
  final bool pictureUploadFailed;

  CreateMessState({
    this.currentStep = 0,
    this.isLoading = false,
    this.errorMessage,
    Map<String, dynamic>? formData,
    this.messImage, // Keep XFile?
    this.isSubmitting = false,
    this.pictureUploadFailed = false,
  }) : formData = formData ?? {};

  CreateMessState copyWith({
    int? currentStep,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? formData,
    // *** FIX: Change type to XFile? ***
    XFile? messImage,
    bool clearImage = false,
    bool? isSubmitting,
    bool? pictureUploadFailed,
  }) {
    return CreateMessState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      formData: formData ?? this.formData,
      // *** FIX: Handle XFile? ***
      messImage: clearImage ? null : messImage ?? this.messImage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pictureUploadFailed: pictureUploadFailed ?? this.pictureUploadFailed,
    );
  }
}

// StateNotifier
class CreateMessNotifier extends StateNotifier<CreateMessState> {
  final MessRepository _messRepository;
  final Ref ref;

  CreateMessNotifier(this._messRepository, this.ref) : super(CreateMessState());

  void nextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void updateFormData(String key, dynamic value) {
    final newFormData = Map<String, dynamic>.from(state.formData);
    newFormData[key] = value;
    state = state.copyWith(formData: newFormData);
  }

  void updateNestedFormData(List<String> keys, dynamic value) {
    final newFormData = Map<String, dynamic>.from(state.formData);
    Map<String, dynamic> currentLevel = newFormData;

    for (int i = 0; i < keys.length - 1; i++) {
      if (!currentLevel.containsKey(keys[i]) || currentLevel[keys[i]] is! Map) {
        currentLevel[keys[i]] = <String, dynamic>{};
      }
      currentLevel = currentLevel[keys[i]] as Map<String, dynamic>;
    }
    currentLevel[keys.last] = value;
    state = state.copyWith(formData: newFormData);
  }

  void setMessImage(XFile? image) {
    state = state.copyWith(messImage: image, clearImage: image == null);
  }

  // Handle location picking and reverse geocoding
  // Existing method: setLocation
  Future<void> setLocation(LatLng latLng) async {
    // 1. Update location coordinates immediately
    // The API takes plain longitude/latitude numbers now, not a GeoJSON
    // {type, coordinates} object.
    final newLocation = Location(
      longitude: latLng.longitude,
      latitude: latLng.latitude,
    );

    final currentFormData = Map<String, dynamic>.from(state.formData);
    currentFormData['location'] = newLocation.toJson();

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      formData: currentFormData,
    );
  }

  Future<bool> submitMess() async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      // Only plans the manager actually priced get sent. A mess that offers
      // lunch only is a real thing, so the other preset rows are dropped rather
      // than submitted with a null rate the server would reject.
      final plans = (state.formData['plans'] as List?)
          ?.whereType<Map>()
          .where((plan) {
            final rate = plan['rateRupees'];
            return plan['name'] != null && rate is num && rate > 0;
          })
          .map((plan) => Map<String, dynamic>.from(plan))
          .toList();

      if (plans == null || plans.isEmpty) {
        throw 'Set a monthly rate for at least one plan.';
      }

      final dataToSend = Map<String, dynamic>.from(state.formData);
      dataToSend['plans'] = plans;

      // Create the mess via repository. The picture travels as its own
      // request, so it can fail without the mess failing.
      final result =
          await _messRepository.createMess(dataToSend, state.messImage);
      final pictureFailed =
          state.messImage != null && !result.pictureUploaded;

      // Re-read the profile rather than patching hasMess by hand: the server
      // also returns the new messId, and the router keys off this state to let
      // the manager out of the create-mess wizard.
      await ref.read(authProvider.notifier).refreshProfile();

      state = state.copyWith(
        isSubmitting: false,
        pictureUploadFailed: pictureFailed,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }
}

// Provider definition
final createMessProvider =
    StateNotifierProvider<CreateMessNotifier, CreateMessState>((ref) {
  final messRepository = ref.watch(messRepositoryProvider);
  return CreateMessNotifier(messRepository, ref);
});
