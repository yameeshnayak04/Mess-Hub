// lib/features/mess_onboarding/presentation/screens/create_mess_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/screens/manager_dashboard_screen.dart';
import 'package:mess_management_system/features/mess_onboarding/presentation/providers/mess_onboarding_provider.dart';

class CreateMessScreen extends ConsumerStatefulWidget {
  const CreateMessScreen({super.key});

  @override
  ConsumerState<CreateMessScreen> createState() => _CreateMessScreenState();
}

class _CreateMessScreenState extends ConsumerState<CreateMessScreen> {
  int _currentStep = 0;

  // --- Form Keys for each step to handle validation ---
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();

  // --- Form Controllers & State Variables ---
  final _messNameController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerContactController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _dailyThaliRateController = TextEditingController();
  final _rebateDaysController = TextEditingController(text: '3');

  String _serviceType = 'Both';
  String _cuisine = 'Veg';

  @override
  void dispose() {
    _messNameController.dispose();
    _managerNameController.dispose();
    _managerContactController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _dailyThaliRateController.dispose();
    _rebateDaysController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // Final check before submission
    if (!_validateAllSteps()) return;

    final messData = {
      "name": _messNameController.text.trim(),
      "managerContact": _managerContactController.text.trim(),
      "address": _addressController.text.trim(),
      "city": _cityController.text.trim(),
      "location": {
        "type": "Point",
        "coordinates": [75.8577, 22.7196]
      }, // Placeholder
      "serviceType": _serviceType,
      "cuisine": _cuisine,
      "dailyThaliRate": double.tryParse(_dailyThaliRateController.text.trim()),
      "mealPlans": [
        {
          "name": "Full Day",
          "priceHistory": [
            {"price": 3000}
          ], // Placeholder
          "perDayRebateRate": 100 // Placeholder
        }
      ],
      "rebateMinDays": int.tryParse(_rebateDaysController.text.trim()) ?? 3,
      // Add other rules from your model...
    };

    final notifier = ref.read(messOnboardingProvider.notifier);
    try {
      await notifier.createMess(messData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Mess created successfully! Welcome to your dashboard.'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const ManagerDashboardScreen()),
            (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _validateAllSteps() {
    return _step1Key.currentState!.validate() &&
        _step2Key.currentState!.validate() &&
        _step4Key.currentState!.validate();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messOnboardingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Mess Profile')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          // Validate current step before proceeding
          bool isStepValid = false;
          if (_currentStep == 0)
            isStepValid = _step1Key.currentState!.validate();
          else if (_currentStep == 1)
            isStepValid = _step2Key.currentState!.validate();
          else if (_currentStep == 3)
            isStepValid = _step4Key.currentState!.validate();
          else
            isStepValid = true; // For steps without forms

          if (isStepValid) {
            if (_currentStep < 4) {
              setState(() => _currentStep += 1);
            } else {
              _submitForm();
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 4;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(children: [
                    ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(isLastStep ? 'Create Mess' : 'Next')),
                    if (_currentStep > 0)
                      TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back')),
                  ]),
          );
        },
        steps: [
          Step(
            title: const Text('Basic Information'),
            subtitle: const Text('Your mess identity'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _step1Key,
              child: Column(children: [
                TextFormField(
                    controller: _messNameController,
                    decoration: const InputDecoration(labelText: 'Mess Name*'),
                    validator: (v) =>
                        v!.isEmpty ? 'Mess name is required' : null),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _managerNameController,
                    decoration: const InputDecoration(
                        labelText: 'Your Name (Manager)*'),
                    validator: (v) =>
                        v!.isEmpty ? 'Your name is required' : null),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _managerContactController,
                    decoration: const InputDecoration(
                        labelText: 'Public Contact Number*',
                        prefixText: '+91 '),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (v) => v!.length != 10
                        ? 'Enter a valid 10-digit number'
                        : null),
              ]),
            ),
          ),
          Step(
            title: const Text('Location'),
            subtitle: const Text('Where customers can find you'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _step2Key,
              child: Column(children: [
                TextFormField(
                    controller: _addressController,
                    decoration:
                        const InputDecoration(labelText: 'Full Address*'),
                    validator: (v) =>
                        v!.isEmpty ? 'Address is required' : null),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City*'),
                    validator: (v) => v!.isEmpty ? 'City is required' : null),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.location_pin),
                    label: const Text('Set Location on Map')),
              ]),
            ),
          ),
          Step(
            title: const Text('Services & Timings'),
            subtitle: const Text('What and when you serve'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Cuisine Type:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<String>(
                  title: const Text('Vegetarian'),
                  value: 'Veg',
                  groupValue: _cuisine,
                  onChanged: (v) => setState(() => _cuisine = v!)),
              RadioListTile<String>(
                  title: const Text('Non-Vegetarian'),
                  value: 'Non-Veg',
                  groupValue: _cuisine,
                  onChanged: (v) => setState(() => _cuisine = v!)),
              RadioListTile<String>(
                  title: const Text('Both'),
                  value: 'Both',
                  groupValue: _cuisine,
                  onChanged: (v) => setState(() => _cuisine = v!)),
              // TODO: Add dynamic time pickers for Timings
            ]),
          ),
          Step(
            title: const Text('Pricing'),
            subtitle: const Text('How you charge'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _step4Key,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer Types Accepted:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    RadioListTile<String>(
                        title: const Text('Monthly and Daily'),
                        value: 'Both',
                        groupValue: _serviceType,
                        onChanged: (v) => setState(() => _serviceType = v!)),
                    RadioListTile<String>(
                        title: const Text('Monthly Only'),
                        value: 'Monthly Only',
                        groupValue: _serviceType,
                        onChanged: (v) => setState(() => _serviceType = v!)),
                    RadioListTile<String>(
                        title: const Text('Daily Only'),
                        value: 'Daily Only',
                        groupValue: _serviceType,
                        onChanged: (v) => setState(() => _serviceType = v!)),
                    if (_serviceType != 'Monthly Only') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _dailyThaliRateController,
                          decoration: const InputDecoration(
                              labelText: 'Per-Thali Rate for Daily Users*'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v!.isEmpty ? 'Rate is required' : null),
                    ],
                    if (_serviceType != 'Daily Only') ...[
                      const SizedBox(height: 16),
                      const Text(
                          'Monthly plans will be configured from your dashboard.'),
                    ],
                  ]),
            ),
          ),
          Step(
            title: const Text('Rules & Policies'),
            subtitle: const Text('Your business rules'),
            isActive: _currentStep >= 4,
            state: StepState.indexed,
            content: Column(children: [
              TextFormField(
                  controller: _rebateDaysController,
                  decoration: const InputDecoration(
                      labelText: 'Minimum consecutive leave days for rebate'),
                  keyboardType: TextInputType.number),
              // TODO: Add widgets for other rules (leave cutoff, billing policy, etc.)
            ]),
          ),
        ],
      ),
    );
  }
}
