import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/utils/constants.dart';

class CreateMessWizardScreen extends ConsumerStatefulWidget {
  const CreateMessWizardScreen({super.key});

  @override
  ConsumerState<CreateMessWizardScreen> createState() =>
      _CreateMessWizardScreenState();
}

class _CreateMessWizardScreenState
    extends ConsumerState<CreateMessWizardScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Basic Info
  final _messNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  File? _messImage;
  String _serviceType = 'Monthly Only';
  String _cuisine = 'Veg';

  // Step 2: Location
  double? _latitude;
  double? _longitude;

  // Step 3: Pricing
  final _dailyRateController = TextEditingController();
  final _plan1NameController = TextEditingController(text: 'Lunch Only');
  final _plan1RateController = TextEditingController();
  final _plan2NameController = TextEditingController(text: 'Dinner Only');
  final _plan2RateController = TextEditingController();
  final _plan3NameController = TextEditingController(text: 'Lunch + Dinner');
  final _plan3RateController = TextEditingController();

  // Step 4: Leave Rules
  final _minLeaveDaysController = TextEditingController();
  final _rebatePerThaliController = TextEditingController();

  // Step 5: Meal Rules
  final _skipAllowanceController = TextEditingController();
  TimeOfDay? _lunchStart;
  TimeOfDay? _lunchEnd;
  TimeOfDay? _dinnerStart;
  TimeOfDay? _dinnerEnd;

  @override
  void dispose() {
    _messNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _dailyRateController.dispose();
    _plan1NameController.dispose();
    _plan1RateController.dispose();
    _plan2NameController.dispose();
    _plan2RateController.dispose();
    _plan3NameController.dispose();
    _plan3RateController.dispose();
    _minLeaveDaysController.dispose();
    _rebatePerThaliController.dispose();
    _skipAllowanceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _messImage = File(image.path);
      });
    }
  }

  Future<void> _selectTime(
      BuildContext context, bool isStart, bool isLunch) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isLunch) {
          if (isStart) {
            _lunchStart = picked;
          } else {
            _lunchEnd = picked;
          }
        } else {
          if (isStart) {
            _dinnerStart = picked;
          } else {
            _dinnerEnd = picked;
          }
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _messNameController.text.isNotEmpty &&
            _contactController.text.length == 10 &&
            _addressController.text.isNotEmpty &&
            _cityController.text.isNotEmpty;
      case 1:
        return _latitude != null && _longitude != null;
      case 2:
        if (_serviceType == 'Both Daily & Monthly' &&
            _dailyRateController.text.isEmpty) {
          return false;
        }
        return _plan1RateController.text.isNotEmpty &&
            _plan2RateController.text.isNotEmpty &&
            _plan3RateController.text.isNotEmpty;
      case 3:
        return _minLeaveDaysController.text.isNotEmpty &&
            _rebatePerThaliController.text.isNotEmpty;
      case 4:
        return _skipAllowanceController.text.isNotEmpty &&
            _lunchStart != null &&
            _lunchEnd != null &&
            _dinnerStart != null &&
            _dinnerEnd != null;
      default:
        return false;
    }
  }

  Future<void> _submitMess() async {
    setState(() => _isSubmitting = true);

    try {
      // API call would go here
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mess created successfully!')),
        );
        context.go(RouteNames.managerHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create mess: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Mess'),
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
                      color: index <= _currentStep
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
              child: _buildStepContent(),
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
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _currentStep--);
                        },
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: _currentStep == 4 ? 'Finish Setup' : 'Next',
                      onPressed: _validateCurrentStep()
                          ? () {
                              if (_currentStep == 4) {
                                _submitMess();
                              } else {
                                setState(() => _currentStep++);
                              }
                            }
                          : null,
                      isLoading: _isSubmitting,
                      icon:
                          _currentStep == 4 ? Icons.check : Icons.arrow_forward,
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo();
      case 1:
        return _buildStep2Location();
      case 2:
        return _buildStep3Pricing();
      case 3:
        return _buildStep4LeaveRules();
      case 4:
        return _buildStep5MealRules();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1BasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Basic Information',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about your mess',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 24),

        // Mess Image
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryOrange,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _messImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _messImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: AppTheme.primaryOrange,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add Photo',
                          style: TextStyle(color: AppTheme.primaryOrange),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _messNameController,
          decoration: const InputDecoration(
            labelText: 'Mess Name',
            hintText: 'Enter your mess name',
            prefixIcon: Icon(Icons.restaurant),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _contactController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: const InputDecoration(
            labelText: 'Contact Number',
            hintText: 'Enter contact number',
            prefixIcon: Icon(Icons.phone),
            counterText: '',
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            hintText: 'Enter full address',
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'City',
            hintText: 'Enter city',
            prefixIcon: Icon(Icons.location_city),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _serviceType,
          decoration: const InputDecoration(
            labelText: 'Service Type',
            prefixIcon: Icon(Icons.business),
          ),
          items: const [
            DropdownMenuItem(
                value: 'Monthly Only', child: Text('Monthly Only')),
            DropdownMenuItem(
                value: 'Both Daily & Monthly',
                child: Text('Both Daily & Monthly')),
          ],
          onChanged: (value) {
            setState(() => _serviceType = value!);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _cuisine,
          decoration: const InputDecoration(
            labelText: 'Cuisine',
            prefixIcon: Icon(Icons.restaurant_menu),
          ),
          items: const [
            DropdownMenuItem(value: 'Veg', child: Text('Veg')),
            DropdownMenuItem(value: 'Non-Veg', child: Text('Non-Veg')),
            DropdownMenuItem(value: 'Both', child: Text('Both')),
          ],
          onChanged: (value) {
            setState(() => _cuisine = value!);
          },
        ),
      ],
    );
  }

  Widget _buildStep2Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Location',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Set your mess location on map',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.map,
                  size: 80,
                  color: AppTheme.primaryOrange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Map Integration',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'flutter_map with OpenStreetMap\nwould be integrated here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Simulate location selection
                    setState(() {
                      _latitude = 28.7041;
                      _longitude = 77.1025;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location selected')),
                    );
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use Current Location'),
                ),
              ],
            ),
          ),
        ),
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 16),
          Card(
            color: AppTheme.successGreen.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.successGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Location set: $_latitude, $_longitude',
                      style: const TextStyle(color: AppTheme.successGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3Pricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Pricing',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Set your meal plans and rates',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 24),

        if (_serviceType == 'Both Daily & Monthly') ...[
          TextField(
            controller: _dailyRateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily Thali Rate',
              hintText: 'Enter rate per thali',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 24),
        ],

        Text(
          'Monthly Plans',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),

        // Plan 1
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _plan1NameController,
                decoration: const InputDecoration(
                  labelText: 'Plan 1 Name',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _plan1RateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rate',
                  prefixText: '₹',
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Plan 2
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _plan2NameController,
                decoration: const InputDecoration(
                  labelText: 'Plan 2 Name',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _plan2RateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rate',
                  prefixText: '₹',
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Plan 3
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _plan3NameController,
                decoration: const InputDecoration(
                  labelText: 'Plan 3 Name',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _plan3RateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rate',
                  prefixText: '₹',
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4LeaveRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 4: Leave Rules',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Set leave and rebate policies',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _minLeaveDaysController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minimum Leave Days for Rebate',
            hintText: 'Enter number of days',
            prefixIcon: Icon(Icons.calendar_today),
            helperText:
                'Minimum consecutive days required for rebate eligibility',
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _rebatePerThaliController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Rebate Per Thali',
            hintText: 'Enter amount',
            prefixIcon: Icon(Icons.currency_rupee),
            helperText: 'Amount to be refunded per skipped meal',
          ),
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStep5MealRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 5: Meal Rules',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Set meal timings and skip policies',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _skipAllowanceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Skip Allowance Percentage',
            hintText: 'Enter percentage (0-100)',
            prefixIcon: Icon(Icons.percent),
            helperText: 'Percentage of base rate counted for skipped meals',
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 24),

        // Lunch Timings
        Text(
          'Lunch Timings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectTime(context, true, true),
                icon: const Icon(Icons.access_time),
                label: Text(_formatTime(_lunchStart)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('to'),
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectTime(context, false, true),
                icon: const Icon(Icons.access_time),
                label: Text(_formatTime(_lunchEnd)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Dinner Timings
        Text(
          'Dinner Timings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectTime(context, true, false),
                icon: const Icon(Icons.access_time),
                label: Text(_formatTime(_dinnerStart)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('to'),
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectTime(context, false, false),
                icon: const Icon(Icons.access_time),
                label: Text(_formatTime(_dinnerEnd)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
