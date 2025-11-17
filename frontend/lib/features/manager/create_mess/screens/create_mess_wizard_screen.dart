// lib/features/manager/create_mess/screens/create_mess_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:mess_management_app/features/manager/create_mess/widgets/location_picker_map.dart';
import 'dart:typed_data';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/utils/constants.dart';
import '../providers/create_mess_provider.dart';

class CreateMessWizardScreen extends ConsumerStatefulWidget {
  const CreateMessWizardScreen({super.key});

  @override
  ConsumerState<CreateMessWizardScreen> createState() =>
      _CreateMessWizardScreenState();
}

class _CreateMessWizardScreenState extends ConsumerState<CreateMessWizardScreen>
    with TickerProviderStateMixin {
  final Map<int, GlobalKey<FormState>> _formKeys = {
    0: GlobalKey<FormState>(),
    1: GlobalKey<FormState>(),
    2: GlobalKey<FormState>(),
    3: GlobalKey<FormState>(),
    4: GlobalKey<FormState>(),
  };

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createMessProvider.notifier).updateFormData('plans', [
        {'name': _planNameControllers[0].text, 'rate': null},
        {'name': _planNameControllers[1].text, 'rate': null},
        {'name': _planNameControllers[2].text, 'rate': null},
      ]);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      ref.read(createMessProvider.notifier).setMessImage(image);
    }
  }

  Future<void> _selectTime(
      BuildContext context, bool isStart, bool isLunch) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
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
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay? _getTimeFromState(List<String> keys) {
    final formData = ref.read(createMessProvider).formData;
    dynamic currentLevel = formData;
    try {
      for (final key in keys) {
        if (currentLevel is Map && currentLevel.containsKey(key)) {
          currentLevel = currentLevel[key];
        } else {
          return null;
        }
      }
      if (currentLevel is String) {
        final parts = currentLevel.split(':');
        if (parts.length == 2) {
          return TimeOfDay(
              hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }
    } catch (_) {}
    return null;
  }

  bool _validateCurrentStep(int step, CreateMessState state) {
    final formData = state.formData;
    switch (step) {
      case 0:
        return formData['messName'] != null &&
            formData['contactPhone'] != null &&
            (formData['contactPhone'] as String?)?.length == 10 &&
            formData['serviceType'] != null &&
            formData['cuisine'] != null &&
            formData['basicThaliDetails'] != null &&
            formData['maxCapacity'] != null &&
            (formData['maxCapacity'] as num) > 0;
      case 1:
        return formData['location'] != null &&
            formData['address'] != null &&
            formData['city'] != null;
      case 2:
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
      case 3:
        return formData['rules']?['minLeaveDaysForRebate'] != null &&
            (formData['rules']?['minLeaveDaysForRebate'] as num?)! > 0 &&
            formData['rules']?['rebatePerThali'] != null &&
            (formData['rules']?['rebatePerThali'] as num?)! >= 0;
      case 4:
        return formData['timings']?['lunch']?['start'] != null &&
            formData['timings']?['lunch']?['end'] != null &&
            formData['timings']?['dinner']?['start'] != null &&
            formData['timings']?['dinner']?['end'] != null &&
            formData['rules']?['skipAllowancePercent'] != null &&
            (formData['rules']?['skipAllowancePercent'] as num?)! >= 0;
      default:
        return false;
    }
  }

  Future<void> _submitMess() async {
    final success = await ref.read(createMessProvider.notifier).submitMess();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Mess created successfully!'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      context.go(RouteNames.managerHome);
    } else if (mounted) {
      final error = ref.read(createMessProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed: $error')),
            ],
          ),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Your Mess',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Step ${currentStep + 1} of 5',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            currentStep == 0 ? Icons.close : Icons.arrow_back,
            color: AppTheme.textPrimary,
          ),
          onPressed: currentStep == 0
              ? () => context.go(RouteNames.managerHome)
              : () {
                  notifier.previousStep();
                  _animationController.reset();
                  _animationController.forward();
                },
        ),
      ),
      body: Column(
        children: [
          // Modern Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(5, (index) {
                final isCompleted = index < currentStep;
                final isCurrent = index == currentStep;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: isCompleted || isCurrent
                                ? const LinearGradient(
                                    colors: [
                                      AppTheme.primaryOrange,
                                      Color(0xFFFF8C42)
                                    ],
                                  )
                                : null,
                            color: isCompleted || isCurrent
                                ? null
                                : AppTheme.borderColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                      if (index < 4) const SizedBox(width: 8),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Step Content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  child: Form(
                    key: _formKeys[currentStep],
                    child: _buildStepContent(currentStep, state, notifier),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      notifier.previousStep();
                      _animationController.reset();
                      _animationController.forward();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: currentStep == 0 ? 1 : 2,
                child: PrimaryButton(
                  text: currentStep == 4 ? 'Create Mess' : 'Continue',
                  onPressed: (_validateCurrentStep(currentStep, state) &&
                          !state.isSubmitting)
                      ? () {
                          if (currentStep == 4) {
                            _submitMess();
                          } else {
                            notifier.nextStep();
                            _animationController.reset();
                            _animationController.forward();
                          }
                        }
                      : null,
                  isLoading: state.isSubmitting,
                  icon: currentStep == 4
                      ? Icons.check_circle_outline
                      : Icons.arrow_forward,
                ),
              ),
            ],
          ),
        ),
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
        return _buildStep4Rules(state, notifier);
      case 4:
        return _buildStep5Timings(state, notifier);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1BasicInfo(
      CreateMessState state, CreateMessNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernStepHeader(
          icon: Icons.restaurant_menu,
          title: "Basic Information",
          subtitle: "Let's start with the essentials",
          color: const Color(0xFFFF6B35),
        ),
        const SizedBox(height: 32),

        // Modern Image Picker
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryOrange.withOpacity(0.1),
                    AppTheme.primaryOrange.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.primaryOrange.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: state.messImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate,
                            size: 32,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Add Mess Photo',
                          style: TextStyle(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to upload',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : FutureBuilder<Uint8List>(
                      future: state.messImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(
                                snapshot.data!,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Modern Input Fields
        _buildModernTextField(
          label: 'Mess Name',
          hint: 'Enter your mess name',
          icon: Icons.business,
          initialValue: state.formData['messName'] as String?,
          validator: (value) =>
              value == null || value.isEmpty ? 'Mess name is required' : null,
          onChanged: (value) => notifier.updateFormData('messName', value),
        ),
        const SizedBox(height: 20),

        _buildModernTextField(
          label: 'Contact Number',
          hint: '10-digit mobile number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          initialValue: state.formData['contactPhone'] as String?,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) => value == null || value.length != 10
              ? 'Enter a valid 10-digit number'
              : null,
          onChanged: (value) => notifier.updateFormData('contactPhone', value),
        ),
        const SizedBox(height: 20),

        _buildModernDropdown(
          label: 'Service Type',
          icon: Icons.room_service,
          value: state.formData['serviceType'] as String? ?? 'Monthly Only',
          items: const ['Monthly Only', 'Both Daily & Monthly'],
          onChanged: (value) => notifier.updateFormData('serviceType', value),
        ),
        const SizedBox(height: 20),

        _buildModernDropdown(
          label: 'Cuisine Type',
          icon: Icons.restaurant,
          value: state.formData['cuisine'] as String? ?? 'Veg',
          items: const ['Veg', 'Non-Veg', 'Both'],
          onChanged: (value) => notifier.updateFormData('cuisine', value),
        ),
        const SizedBox(height: 20),

        _buildModernTextField(
          label: 'Maximum Members',
          hint: 'Total capacity',
          icon: Icons.people,
          keyboardType: TextInputType.number,
          initialValue: state.formData['maxCapacity']?.toString(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.trim().isEmpty)
              return 'Maximum members is required';
            final n = int.tryParse(value);
            if (n == null || n <= 0) return 'Enter a valid number > 0';
            return null;
          },
          onChanged: (value) =>
              notifier.updateFormData('maxCapacity', int.tryParse(value) ?? 0),
        ),
        const SizedBox(height: 24),

        // Modern Switch Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
          ),
          child: SwitchListTile(
            title: const Text(
              'Tiffin Service',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              'Delivery service available',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            value: state.formData['tiffinService'] as bool? ?? false,
            onChanged: (value) =>
                notifier.updateFormData('tiffinService', value),
            activeColor: AppTheme.primaryOrange,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
        ),
        const SizedBox(height: 20),

        _buildModernTextField(
          label: 'Basic Thali Details',
          hint: 'e.g., 4 Roti, Dal, Sabzi, Rice',
          icon: Icons.lunch_dining,
          initialValue: state.formData['basicThaliDetails'] as String?,
          maxLines: 3,
          validator: (value) => value == null || value.isEmpty
              ? 'Thali details are required'
              : null,
          onChanged: (value) =>
              notifier.updateFormData('basicThaliDetails', value),
        ),
      ],
    );
  }

  Widget _buildStep2Location(
      CreateMessState state, CreateMessNotifier notifier) {
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
        _buildModernStepHeader(
          icon: Icons.location_on,
          title: "Location Details",
          subtitle: "Pin your mess location on the map",
          color: const Color(0xFF4ECDC4),
        ),
        const SizedBox(height: 24),

        // Responsive Map Container
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate height based on screen size - minimum 400, maximum 500
            final screenHeight = MediaQuery.of(context).size.height;
            final mapHeight = (screenHeight * 0.5).clamp(400.0, 500.0);

            return Container(
              height: mapHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LocationPickerMap(
                  initialLocation: initialMapLocation,
                  onLocationSelected: (LatLng latLng) {
                    notifier.setLocation(latLng);
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        if (displayLat != null && displayLng != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryOrange.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.my_location,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coordinates',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${displayLat.toStringAsFixed(6)}, ${displayLng.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        _buildModernTextField(
          label: 'Full Address',
          hint: 'Building, Street, Area',
          icon: Icons.home,
          initialValue: state.formData['address'] as String?,
          maxLines: 3,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Address is required'
              : null,
          onChanged: (value) => notifier.updateFormData('address', value),
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          label: 'City',
          hint: 'Your city name',
          icon: Icons.location_city,
          initialValue: state.formData['city'] as String?,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'City is required' : null,
          onChanged: (value) => notifier.updateFormData('city', value),
        ),
      ],
    );
  }

  Widget _buildStep3Pricing(
      CreateMessState state, CreateMessNotifier notifier) {
    final serviceType = state.formData['serviceType'] as String?;
    final plans =
        (state.formData['plans'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernStepHeader(
          icon: Icons.payments,
          title: "Pricing Plans",
          subtitle: "Set competitive rates for your services",
          color: const Color(0xFF95E1D3),
        ),
        const SizedBox(height: 24),
        if (serviceType == 'Both Daily & Monthly') ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryOrange.withOpacity(0.1),
                  AppTheme.primaryOrange.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryOrange.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: AppTheme.primaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Daily Thali Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  label: 'Rate per Thali',
                  hint: 'Enter daily rate',
                  prefixText: '₹ ',
                  keyboardType: TextInputType.number,
                  initialValue: state.formData['dailyThaliRate']?.toString(),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Daily rate is required';
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0)
                      return 'Enter a valid rate > 0';
                    return null;
                  },
                  onChanged: (value) => notifier.updateFormData(
                      'dailyThaliRate', double.tryParse(value) ?? 0.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
        const Text(
          'Monthly Subscription Plans',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure pricing for monthly packages',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.borderColor.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _planNameControllers[index].text,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    label: 'Monthly Rate',
                    hint: 'Enter rate',
                    prefixText: '₹ ',
                    keyboardType: TextInputType.number,
                    initialValue: plans[index]['rate']?.toString(),
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
                        'name': _planNameControllers[index].text,
                        'rate': double.tryParse(value)
                      };
                      notifier.updateFormData('plans', newPlans);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep4Rules(CreateMessState state, CreateMessNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernStepHeader(
          icon: Icons.policy,
          title: "Mess Policies",
          subtitle: "Define rules and terms for members",
          color: const Color(0xFFFFB347),
        ),
        const SizedBox(height: 24),
        _buildModernTextField(
          label: 'Minimum Leave Days for Rebate',
          hint: 'e.g., 3 days',
          icon: Icons.event_available,
          keyboardType: TextInputType.number,
          initialValue:
              state.formData['rules']?['minLeaveDaysForRebate']?.toString(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
        const SizedBox(height: 20),
        _buildModernTextField(
          label: 'Rebate Per Thali',
          hint: 'Amount to be refunded',
          icon: Icons.money_off,
          prefixText: '₹ ',
          keyboardType: TextInputType.number,
          initialValue: state.formData['rules']?['rebatePerThali']?.toString(),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Rebate amount required';
            if (double.tryParse(value) == null || double.parse(value) < 0)
              return 'Enter valid amount >= 0';
            return null;
          },
          onChanged: (value) => notifier.updateNestedFormData(
              ['rules', 'rebatePerThali'], double.tryParse(value) ?? 0.0),
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          label: 'Security Deposit (Optional)',
          hint: 'One-time deposit amount',
          icon: Icons.account_balance_wallet,
          prefixText: '₹ ',
          keyboardType: TextInputType.number,
          initialValue: state.formData['rules']?['securityDeposit']?.toString(),
          onChanged: (value) => notifier.updateNestedFormData(
              ['rules', 'securityDeposit'], double.tryParse(value)),
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          label: 'Minimum Monthly Charge (Optional)',
          hint: 'Minimum billing amount',
          icon: Icons.credit_card,
          prefixText: '₹ ',
          keyboardType: TextInputType.number,
          initialValue:
              state.formData['rules']?['minMonthlyCharge']?.toString(),
          onChanged: (value) => notifier.updateNestedFormData(
              ['rules', 'minMonthlyCharge'], double.tryParse(value)),
        ),
      ],
    );
  }

  Widget _buildStep5Timings(
      CreateMessState state, CreateMessNotifier notifier) {
    final lunchStart = _getTimeFromState(['timings', 'lunch', 'start']);
    final lunchEnd = _getTimeFromState(['timings', 'lunch', 'end']);
    final dinnerStart = _getTimeFromState(['timings', 'dinner', 'start']);
    final dinnerEnd = _getTimeFromState(['timings', 'dinner', 'end']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernStepHeader(
          icon: Icons.schedule,
          title: "Operating Hours",
          subtitle: "Set meal timings and skip policies",
          color: const Color(0xFF667EEA),
        ),
        const SizedBox(height: 24),
        _buildModernTextField(
          label: 'Skip Allowance Percentage',
          hint: 'e.g., 10%',
          icon: Icons.percent,
          suffixText: '%',
          keyboardType: TextInputType.number,
          initialValue:
              state.formData['rules']?['skipAllowancePercent']?.toString() ??
                  '0',
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
        const SizedBox(height: 32),
        _buildTimingSection(
          context: context,
          title: 'Lunch Service',
          icon: Icons.wb_sunny,
          color: const Color(0xFFFFB347),
          startTime: lunchStart,
          endTime: lunchEnd,
          onStartTap: () => _selectTime(context, true, true),
          onEndTap: () => _selectTime(context, false, true),
        ),
        const SizedBox(height: 24),
        _buildTimingSection(
          context: context,
          title: 'Dinner Service',
          icon: Icons.nightlight_round,
          color: const Color(0xFF667EEA),
          startTime: dinnerStart,
          endTime: dinnerEnd,
          onStartTap: () => _selectTime(context, true, false),
          onEndTap: () => _selectTime(context, false, false),
        ),
      ],
    );
  }

  // Modern UI Helper Widgets
  Widget _buildModernStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required String hint,
    IconData? icon,
    String? prefixText,
    String? suffixText,
    TextInputType? keyboardType,
    String? initialValue,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: AppTheme.primaryOrange, size: 20)
                : null,
            prefixText: prefixText,
            suffixText: suffixText,
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.borderColor.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.borderColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryOrange,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.errorRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderColor.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryOrange, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTimingSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
    required VoidCallback onStartTap,
    required VoidCallback onEndTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeButton(
                  label: 'Start Time',
                  time: startTime,
                  onTap: onStartTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeButton(
                  label: 'End Time',
                  time: endTime,
                  onTap: onEndTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: time == null
                  ? AppTheme.errorRed.withOpacity(0.05)
                  : AppTheme.primaryOrange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: time == null
                    ? AppTheme.errorRed.withOpacity(0.3)
                    : AppTheme.primaryOrange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color:
                      time == null ? AppTheme.errorRed : AppTheme.primaryOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        time == null ? AppTheme.errorRed : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
