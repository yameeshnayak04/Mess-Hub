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

  CreateMessState({
    this.currentStep = 0,
    this.isLoading = false,
    this.errorMessage,
    Map<String, dynamic>? formData,
    this.messImage, // Keep XFile?
    this.isSubmitting = false,
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
  }) {
    return CreateMessState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      formData: formData ?? this.formData,
      // *** FIX: Handle XFile? ***
      messImage: clearImage ? null : messImage ?? this.messImage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
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
    final newLocation = Location(
      type: 'Point',
      coordinates: [latLng.longitude, latLng.latitude],
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
      final plans = (state.formData['plans'] as List?)
          ?.where((p) => p is Map && p['name'] != null && p['rate'] != null)
          .toList();

      if (plans == null || plans.isEmpty) {
        throw 'Please add at least one monthly plan.';
      }

      final dataToSend = Map<String, dynamic>.from(state.formData);
      dataToSend['plans'] = plans;

      // Create the mess via repository
      await _messRepository.createMess(dataToSend, state.messImage);

      // *** FIX: Update Auth Provider State ***
      final authNotifier = ref.read(authProvider.notifier);
      final currentUserState = ref.read(authProvider);

      // Check if user data is available before updating
      if (currentUserState.hasValue && currentUserState.value != null) {
        final currentUser = currentUserState.value!;
        // Create a new user object with hasMess set to true
        final updatedUser = currentUser.copyWith(hasMess: true);
        // Manually update the auth state
        authNotifier.state = AsyncValue.data(updatedUser);
      } else {
        // Might need to trigger a profile refresh instead if user data isn't loaded yet
        // authNotifier.refreshProfile();
      }

      state = state.copyWith(isSubmitting: false);
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
  // Pass ref to the notifier
  return CreateMessNotifier(messRepository, ref);
});
