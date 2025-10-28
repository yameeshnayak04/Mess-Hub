// lib/features/manager/create_mess/screens/create_mess_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mess_management_app/features/manager/create_mess/widgets/location_picker_map.dart';
import 'dart:typed_data';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/utils/constants.dart';
import '../../../../models/mess.dart'; // Import MessPlan model
import '../providers/create_mess_provider.dart';

class CreateMessWizardScreen extends ConsumerStatefulWidget {
  const CreateMessWizardScreen({super.key});

  @override
  ConsumerState<CreateMessWizardScreen> createState() =>
      _CreateMessWizardScreenState();
}

class _CreateMessWizardScreenState
    extends ConsumerState<CreateMessWizardScreen> {
  final Map<int, GlobalKey<FormState>> _formKeys = {
    0: GlobalKey<FormState>(),
    1: GlobalKey<FormState>(), // Location doesn't need form key
    2: GlobalKey<FormState>(),
    3: GlobalKey<FormState>(),
    4: GlobalKey<FormState>(),
  };

  // Controllers for plans (example, can be made dynamic)
  final List<TextEditingController> _planNameControllers = [
    TextEditingController(text: 'Monthly (Both Meals)'),
    TextEditingController(text: 'Monthly (Lunch Only)'),
    TextEditingController(text: 'Monthly (Dinner Only)'),
  ];
  final List<TextEditingController> _planRateControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize default plans in provider state if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createMessProvider.notifier).updateFormData('plans', [
        {'name': _planNameControllers[0].text, 'rate': null},
        {'name': _planNameControllers[1].text, 'rate': null},
        {'name': _planNameControllers[2].text, 'rate': null},
      ]);
      // Set initial location for map (Guna, MP)
    });
  }

  @override
  void dispose() {
    for (var controller in _planNameControllers) {
      controller.dispose();
    }
    for (var controller in _planRateControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // No change needed here, picker returns XFile
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Provider now expects XFile
      ref.read(createMessProvider.notifier).setMessImage(image);
    }
  }

  Future<void> _selectTime(
      BuildContext context, bool isStart, bool isLunch) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final path = isLunch
          ? (isStart
              ? ['timings', 'lunch', 'start']
              : ['timings', 'lunch', 'end'])
          : (isStart
              ? ['timings', 'dinner', 'start']
              : ['timings', 'dinner', 'end']);
      ref
          .read(createMessProvider.notifier)
          .updateNestedFormData(path, formattedTime);
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Helper to get time from provider state
  TimeOfDay? _getTimeFromState(List<String> keys) {
    final formData = ref.read(createMessProvider).formData;
    dynamic currentLevel = formData;
    try {
      for (final key in keys) {
        if (currentLevel is Map && currentLevel.containsKey(key)) {
          currentLevel = currentLevel[key];
        } else {
          return null; // Path doesn't exist
        }
      }
      if (currentLevel is String) {
        final parts = currentLevel.split(':');
        if (parts.length == 2) {
          return TimeOfDay(
              hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }
    } catch (_) {
      // Ignore parsing errors
    }
    return null;
  }

  // Simplified validation - checks if required fields for the *current* step have values in provider state
  bool _validateCurrentStep(int step, CreateMessState state) {
    final formData = state.formData;
    switch (step) {
      case 0: // Basic Info
        return formData['messName'] != null &&
            formData['contactPhone'] != null &&
            (formData['contactPhone'] as String?)?.length == 10 &&
            formData['serviceType'] != null &&
            formData['cuisine'] != null &&
            formData['basicThaliDetails'] != null; // Added tiffin details
      case 1: // Location
        return formData['location'] != null &&
            formData['address'] != null &&
            formData['city'] != null;
      case 2: // Pricing
        final plans = formData['plans'] as List?;
        bool allPlansValid = plans?.every((p) =>
                p is Map &&
                p['name'] != null &&
                p['rate'] != null &&
                (p['rate'] as num?)! > 0) ??
            false;
        bool dailyRateValid = true;
        if (formData['serviceType'] == 'Both Daily & Monthly') {
          dailyRateValid = formData['dailyThaliRate'] != null &&
              (formData['dailyThaliRate'] as num?)! > 0;
        }
        return allPlansValid && dailyRateValid;
      case 3: // Rules
        return formData['rules']?['minLeaveDaysForRebate'] != null &&
            (formData['rules']?['minLeaveDaysForRebate'] as num?)! > 0 &&
            formData['rules']?['rebatePerThali'] != null &&
            (formData['rules']?['rebatePerThali'] as num?)! >= 0;
      case 4: // Timings
        return formData['timings']?['lunch']?['start'] != null &&
            formData['timings']?['lunch']?['end'] != null &&
            formData['timings']?['dinner']?['start'] != null &&
            formData['timings']?['dinner']?['end'] != null &&
            formData['rules']?['skipAllowancePercent'] !=
                null && // Added skip allowance
            (formData['rules']?['skipAllowancePercent'] as num?)! >= 0;
      default:
        return false;
    }
  }

  Future<void> _submitMess() async {
    final success = await ref.read(createMessProvider.notifier).submitMess();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mess created successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      // Consider refreshing manager home data before navigating
      context.go(RouteNames.managerHome);
    } else if (mounted) {
      final error = ref.read(createMessProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create mess: $error'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createMessProvider);
    final notifier = ref.read(createMessProvider.notifier);
    final currentStep = state.currentStep;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Your Mess (Step ${currentStep + 1} of 5)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Go back to manager home only if on the first step
          onPressed: currentStep == 0
              ? () => context.go(RouteNames.managerHome)
              : notifier.previousStep,
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(
                5,
                (index) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index <= currentStep
                          ? AppTheme.primaryOrange
                          : AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Step Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKeys[currentStep],
                child: _buildStepContent(currentStep, state, notifier),
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: notifier.previousStep,
                        child: const Text('Back'),
                      ),
                    ),
                  if (currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: currentStep == 4 ? 'Finish Setup' : 'Next',
                      // Disable button if validation fails or submitting
                      onPressed: (_validateCurrentStep(currentStep, state) &&
                              !state.isSubmitting)
                          ? () {
                              if (currentStep == 4) {
                                _submitMess();
                              } else {
                                notifier.nextStep();
                              }
                            }
                          : null,
                      isLoading: state.isSubmitting,
                      icon:
                          currentStep == 4 ? Icons.check : Icons.arrow_forward,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
      int step, CreateMessState state, CreateMessNotifier notifier) {
    switch (step) {
      case 0:
        return _buildStep1BasicInfo(state, notifier);
      case 1:
        return _buildStep2Location(state, notifier);
      case 2:
        return _buildStep3Pricing(state, notifier);
      case 3:
        return _buildStep4Rules(state, notifier); // Renamed
      case 4:
        return _buildStep5Timings(state, notifier); // Renamed
      default:
        return const SizedBox();
    }
  }

  // --- Step 1: Basic Info ---
  Widget _buildStep1BasicInfo(
      CreateMessState state, CreateMessNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(context, Icons.info_outline, "Basic Information",
            "Tell us about your mess"),
        const SizedBox(height: 24),

        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryOrange, width: 1.5),
                image: state.messImage != null
                    // *** FIX: Use NetworkImage(xfile.path) for web preview ***
                    ? DecorationImage(
                        image: NetworkImage(state.messImage!.path),
                        fit: BoxFit.cover)
                    : null,
              ),
              // In _buildStep1BasicInfo, replace just the image/child part of the GestureDetector Container:

              child: state.messImage == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo,
                            size: 36, color: AppTheme.primaryOrange),
                        SizedBox(height: 8),
                        Text('Add Photo',
                            style: TextStyle(color: AppTheme.primaryOrange)),
                      ],
                    )
                  : FutureBuilder<Uint8List>(
                      future: state.messImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            snapshot.data!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Mess Name
        TextFormField(
          initialValue: state.formData['messName'] as String?,
          decoration: const InputDecoration(labelText: 'Mess Name *'),
          validator: (value) =>
              value == null || value.isEmpty ? 'Mess Name is required' : null,
          onChanged: (value) => notifier.updateFormData('messName', value),
        ),
        const SizedBox(height: 16),

        // Contact Phone
        TextFormField(
          initialValue: state.formData['contactPhone'] as String?,
          decoration: const InputDecoration(
              labelText: 'Contact Number *', counterText: ""),
          keyboardType: TextInputType.phone,
          maxLength: 10,
          validator: (value) => value == null || value.length != 10
              ? 'Enter a 10-digit contact number'
              : null,
          onChanged: (value) => notifier.updateFormData('contactPhone', value),
        ),
        const SizedBox(height: 16),

        // Service Type Dropdown
        DropdownButtonFormField<String>(
          value: state.formData['serviceType'] as String? ?? 'Monthly Only',
          decoration: const InputDecoration(labelText: 'Service Type *'),
          items: const [
            DropdownMenuItem(
                value: 'Monthly Only', child: Text('Monthly Only')),
            DropdownMenuItem(
                value: 'Both Daily & Monthly',
                child: Text('Both Daily & Monthly')),
          ],
          onChanged: (value) => notifier.updateFormData('serviceType', value),
          validator: (value) =>
              value == null ? 'Service Type is required' : null,
        ),
        const SizedBox(height: 16),

        // Cuisine Dropdown
        DropdownButtonFormField<String>(
          value: state.formData['cuisine'] as String? ?? 'Veg',
          decoration: const InputDecoration(labelText: 'Cuisine Type *'),
          items: const [
            DropdownMenuItem(value: 'Veg', child: Text('Veg')),
            DropdownMenuItem(value: 'Non-Veg', child: Text('Non-Veg')),
            DropdownMenuItem(value: 'Both', child: Text('Both')),
          ],
          onChanged: (value) => notifier.updateFormData('cuisine', value),
          validator: (value) => value == null ? 'Cuisine is required' : null,
        ),
        const SizedBox(height: 16),

        // Tiffin Service Checkbox
        CheckboxListTile(
          title: const Text("Tiffin Service Available?"),
          value: state.formData['tiffinService'] as bool? ?? false,
          onChanged: (bool? value) {
            notifier.updateFormData('tiffinService', value ?? false);
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),

        // Basic Thali Details
        TextFormField(
          initialValue: state.formData['basicThaliDetails'] as String?,
          decoration: const InputDecoration(
            labelText: 'Basic Thali Details *',
            hintText: 'e.g., 4 Roti, Dal, Sabzi, Rice',
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'Thali Details are required'
              : null,
          onChanged: (value) =>
              notifier.updateFormData('basicThaliDetails', value),
          maxLines: 2,
        ),
      ],
    );
  }

  // --- Step 2: Location ---
  // create_mess_wizard_screen.dart

// REPLACE the entire _buildStep2Location(...) with:

  Widget _buildStep2Location(
      CreateMessState state, CreateMessNotifier notifier) {
    // Derive initial center from saved GeoJSON [lng, lat]
    LatLng? initialMapLocation;
    final locationData = state.formData['location'] as Map?;
    final coordinates = locationData?['coordinates'] as List?;
    double? displayLat;
    double? displayLng;
    if (coordinates != null && coordinates.length == 2) {
      displayLng = (coordinates[0] as num).toDouble();
      displayLat = (coordinates[1] as num).toDouble();
      initialMapLocation = LatLng(displayLat, displayLng);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          context,
          Icons.location_on_outlined,
          "Pick Location",
          "Tap map to set your mess location",
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LocationPickerMap(
              initialLocation: initialMapLocation,
              onLocationSelected: (LatLng latLng) {
                notifier.setLocation(latLng);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Display Latitude and Longitude
        if (displayLat != null && displayLng != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Latitude: ${displayLat.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Longitude: ${displayLng.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Editable address field
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Address *',
            hintText: 'Enter full address',
          ),
          initialValue: state.formData['address'] as String?,
          onChanged: (value) => notifier.updateFormData('address', value),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Editable city field (auto-filled by geocoding, but user can override)
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'City *',
            hintText: 'Enter city',
          ),
          initialValue: state.formData['city'] as String?,
          onChanged: (value) => notifier.updateFormData('city', value),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'City is required';
            }
            return null;
          },
        ),

        if (state.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            state.errorMessage!,
            style: const TextStyle(color: AppTheme.errorRed),
          ),
        ],
      ],
    );
  }

  // --- Step 3: Pricing ---
  Widget _buildStep3Pricing(
      CreateMessState state, CreateMessNotifier notifier) {
    final serviceType = state.formData['serviceType'] as String?;
    final plans =
        (state.formData['plans'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(context, Icons.currency_rupee, "Pricing Details",
            "Set your meal plans and rates"),
        const SizedBox(height: 24),

        // Daily Thali Rate (Conditional)
        if (serviceType == 'Both Daily & Monthly') ...[
          TextFormField(
            initialValue: state.formData['dailyThaliRate']?.toString(),
            decoration: const InputDecoration(
                labelText: 'Daily Thali Rate *', prefixText: '₹ '),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Daily rate is required';
              if (double.tryParse(value) == null || double.parse(value) <= 0)
                return 'Enter a valid rate > 0';
              return null;
            },
            onChanged: (value) => notifier.updateFormData(
                'dailyThaliRate', double.tryParse(value) ?? 0.0),
          ),
          const SizedBox(height: 24),
        ],

        // Monthly Plans
        Text('Monthly Plans *', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Define rates for your monthly subscriptions.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),

        // Display existing plans (using initial controllers for simplicity)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            // Use controllers for initial value, but save directly to provider state
            _planRateControllers[index].text =
                plans[index]['rate']?.toString() ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _planNameControllers[
                          index], // Use controller for name display
                      decoration:
                          InputDecoration(labelText: 'Plan ${index + 1} Name'),
                      readOnly: true, // Make name read-only for now
                      // onChanged: (value) {
                      //   // Update name in provider state if allowing edits
                      // },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: ValueKey(
                          'plan_rate_$index'), // Key might help update state
                      initialValue: plans[index]['rate']
                          ?.toString(), // Use initial value from state
                      decoration: const InputDecoration(
                          labelText: 'Rate *', prefixText: '₹ '),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Rate required';
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) return 'Valid rate > 0';
                        return null;
                      },
                      onChanged: (value) {
                        final newPlans = List<Map<String, dynamic>>.from(plans);
                        newPlans[index] = {
                          'name': _planNameControllers[index]
                              .text, // Keep name from controller
                          'rate': double.tryParse(value)
                        };
                        notifier.updateFormData('plans', newPlans);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Add/Remove plan buttons (optional future enhancement)
      ],
    );
  }

  // --- Step 4: Rules ---
  Widget _buildStep4Rules(CreateMessState state, CreateMessNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(context, Icons.rule, "Mess Rules",
            "Define leave, rebate, and deposit policies"),
        const SizedBox(height: 24),

        // Min Leave Days for Rebate
        TextFormField(
          initialValue:
              state.formData['rules']?['minLeaveDaysForRebate']?.toString(),
          decoration: const InputDecoration(
              labelText: 'Minimum Leave Days for Rebate *'),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Min leave days required';
            if (int.tryParse(value) == null || int.parse(value) <= 0)
              return 'Enter valid days > 0';
            return null;
          },
          onChanged: (value) => notifier.updateNestedFormData(
              ['rules', 'minLeaveDaysForRebate'], int.tryParse(value) ?? 1),
        ),
        const SizedBox(height: 16),

        // Rebate Per Thali
        TextFormField(
          initialValue: state.formData['rules']?['rebatePerThali']?.toString(),
          decoration: const InputDecoration(
              labelText: 'Rebate Per Thali *', prefixText: '₹ '),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Rebate amount required';
            if (double.tryParse(value) == null || double.parse(value) < 0)
              return 'Enter valid amount >= 0';
            return null;
          },
          onChanged: (value) => notifier.updateNestedFormData(
              ['rules', 'rebatePerThali'], double.tryParse(value) ?? 0.0),
        ),
        const SizedBox(height: 16),

        // Security Deposit (Optional)
        TextFormField(
          initialValue: state.formData['rules']?['securityDeposit']?.toString(),
          decoration: const InputDecoration(
              labelText: 'Security Deposit (Optional)', prefixText: '₹ '),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                (double.tryParse(value) == null || double.parse(value) < 0)) {
              return 'Enter valid amount >= 0 or leave empty';
            }
            return null;
          },
          onChanged: (value) => notifier.updateNestedFormData(
              ['rules', 'securityDeposit'],
              double.tryParse(value) ?? null), // Send null if empty
        ),
        const SizedBox(height: 16),

        // Minimum Monthly Charge (Optional)
        TextFormField(
          initialValue:
              state.formData['rules']?['minMonthlyCharge']?.toString(),
          decoration: const InputDecoration(
              labelText: 'Minimum Monthly Charge (Optional)', prefixText: '₹ '),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                (double.tryParse(value) == null || double.parse(value) < 0)) {
              return 'Enter valid amount >= 0 or leave empty';
            }
            return null;
          },
          onChanged: (value) => notifier.updateNestedFormData(
              ['rules', 'minMonthlyCharge'],
              double.tryParse(value) ?? null), // Send null if empty
        ),
      ],
    );
  }

  // --- Step 5: Timings ---
  Widget _buildStep5Timings(
      CreateMessState state, CreateMessNotifier notifier) {
    // Get times for display
    final lunchStart = _getTimeFromState(['timings', 'lunch', 'start']);
    final lunchEnd = _getTimeFromState(['timings', 'lunch', 'end']);
    final dinnerStart = _getTimeFromState(['timings', 'dinner', 'start']);
    final dinnerEnd = _getTimeFromState(['timings', 'dinner', 'end']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(context, Icons.timer_outlined, "Meal Timings & Rules",
            "Set operating hours and skip policies"),
        const SizedBox(height: 24),

        // Skip Allowance Percentage
        TextFormField(
          initialValue:
              state.formData['rules']?['skipAllowancePercent']?.toString() ??
                  '0',
          decoration: const InputDecoration(
              labelText: 'Skip Allowance Percentage *', suffixText: '%'),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Skip allowance required';
            final percent = double.tryParse(value);
            if (percent == null || percent < 0 || percent > 100)
              return 'Enter valid % (0-100)';
            return null;
          },
          onChanged: (value) => notifier.updateNestedFormData(
              ['rules', 'skipAllowancePercent'], double.tryParse(value) ?? 0.0),
        ),
        const SizedBox(height: 24),

        // Lunch Timings
        Text('Lunch Timings *', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectTime(context, true, true),
                icon: const Icon(Icons.access_time),
                label: Text(_formatTime(lunchStart)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: lunchStart == null
                            ? AppTheme.errorRed
                            : AppTheme.primaryOrange)),
              ),
            ),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('to')),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectTime(context, false, true),
                icon: const Icon(Icons.access_time),
                label: Text(_formatTime(lunchEnd)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: lunchEnd == null
                            ? AppTheme.errorRed
                            : AppTheme.primaryOrange)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Dinner Timings
        Text('Dinner Timings *',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectTime(context, true, false),
                icon: const Icon(Icons.access_time),
                label: Text(_formatTime(dinnerStart)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: dinnerStart == null
                            ? AppTheme.errorRed
                            : AppTheme.primaryOrange)),
              ),
            ),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('to')),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectTime(context, false, false),
                icon: const Icon(Icons.access_time),
                label: Text(_formatTime(dinnerEnd)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: dinnerEnd == null
                            ? AppTheme.errorRed
                            : AppTheme.primaryOrange)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper for step headers based on prototype
  Widget _buildStepHeader(
      BuildContext context, IconData icon, String title, String subtitle) {
    return Card(
      elevation: 0,
      color: AppTheme.primaryOrange.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primaryOrange.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryOrange, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
