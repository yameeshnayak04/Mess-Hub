// lib/features/mess_onboarding/presentation/screens/create_mess_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/auth/presentation/providers/auth_provider.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/screens/manager_dashboard_shell.dart';
import 'package:mess_management_system/features/mess_onboarding/presentation/providers/mess_onboarding_provider.dart';
import 'package:geolocator/geolocator.dart';

// A helper class to manage the state of each dynamic meal plan form row.
class MealPlanFormState {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController rebateController = TextEditingController();
  String planName = 'Full Day'; // Default value
}

class CreateMessScreen extends ConsumerStatefulWidget {
  const CreateMessScreen({super.key});

  @override
  ConsumerState<CreateMessScreen> createState() => _CreateMessScreenState();
}

class _CreateMessScreenState extends ConsumerState<CreateMessScreen> {
  int _currentStep = 0;

  // Form Keys for each step to handle granular validation.
  final _stepKeys = [
    GlobalKey<FormState>(), // 0: Basic Info
    GlobalKey<FormState>(), // 1: Location
    GlobalKey<FormState>(), // 2: Services
    GlobalKey<FormState>(), // 3: Pricing
    GlobalKey<FormState>(), // 4: Rules
  ];

  // --- Form Controllers & State Variables ---
  final _messNameController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerContactController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _dailyThaliRateController = TextEditingController();
  final _rebateDaysController = TextEditingController(text: '3');
  final _leaveCutoffDayController = TextEditingController(text: '26');
  final _partialRebateController = TextEditingController(text: '50');

  String _cuisine = 'Veg';
  String _serviceType = 'Both';
  String _notEatingRebatePolicy = 'None';
  String _firstMonthPolicy = 'Pro-Rata';

  TimeOfDay _lunchStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lunchEndTime = const TimeOfDay(hour: 14, minute: 30);
  TimeOfDay _dinnerStartTime = const TimeOfDay(hour: 19, minute: 30);
  TimeOfDay _dinnerEndTime = const TimeOfDay(hour: 22, minute: 0);

  // State for location coordinates and dynamic meal plans
  Position? _currentPosition;
  List<MealPlanFormState> _mealPlanForms = [MealPlanFormState()];

  @override
  void initState() {
    super.initState();
    // Pre-fill manager's name from their profile.
    _managerNameController.text = ref.read(authProvider).user?.name ?? '';
  }

  @override
  void dispose() {
    // Dispose all controllers to free up resources
    _messNameController.dispose();
    _managerNameController.dispose();
    _managerContactController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _dailyThaliRateController.dispose();
    _rebateDaysController.dispose();
    _leaveCutoffDayController.dispose();
    _partialRebateController.dispose();
    for (var form in _mealPlanForms) {
      form.priceController.dispose();
      form.rebateController.dispose();
    }
    super.dispose();
  }

  // --- UI HELPER METHODS ---
  Future<void> _selectTime(BuildContext context,
      {required bool isStart, required bool isLunch}) async {
    final initialTime = isLunch
        ? (isStart ? _lunchStartTime : _lunchEndTime)
        : (isStart ? _dinnerStartTime : _dinnerEndTime);
    final newTime =
        await showTimePicker(context: context, initialTime: initialTime);
    if (newTime != null) {
      setState(() {
        if (isLunch) {
          if (isStart)
            _lunchStartTime = newTime;
          else
            _lunchEndTime = newTime;
        } else {
          if (isStart)
            _dinnerStartTime = newTime;
          else
            _dinnerEndTime = newTime;
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    // Handle location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')));
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions are permanently denied.')));
      return;
    }
    // Get location
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location fetched successfully!'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: Colors.red));
    }
  }

  // --- MAIN SUBMIT LOGIC ---
  Future<void> _submitForm() async {
    bool allValid = true;
    // Validate all form steps before allowing submission.
    for (var key in _stepKeys) {
      if (!key.currentState!.validate()) allValid = false;
    }
    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please correct the errors in all steps.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please set your mess location on the map.'),
          backgroundColor: Colors.red));
      return;
    }

    final messData = {
      "name": _messNameController.text.trim(),
      "managerContact": _managerContactController.text.trim(),
      "address": _addressController.text.trim(),
      "city": _cityController.text.trim(),
      "location": {
        "type": "Point",
        "coordinates": [_currentPosition!.longitude, _currentPosition!.latitude]
      },
      "cuisine": _cuisine,
      "serviceType": _serviceType,
      "dailyThaliRate": _serviceType != 'Monthly Only'
          ? double.tryParse(_dailyThaliRateController.text.trim())
          : null,
      "mealPlans": _serviceType == 'Daily Only'
          ? []
          : _mealPlanForms
              .map((form) => {
                    "name": form.planName,
                    "priceHistory": [
                      {"price": double.parse(form.priceController.text)}
                    ],
                    "perDayRebateRate":
                        double.parse(form.rebateController.text),
                  })
              .toList(),
      "timings": {
        "lunch": {
          "start": _lunchStartTime.format(context),
          "end": _lunchEndTime.format(context)
        },
        "dinner": {
          "start": _dinnerStartTime.format(context),
          "end": _dinnerEndTime.format(context)
        }
      },
      "rebateMinDays": int.tryParse(_rebateDaysController.text.trim()),
      "leaveCutoffDay": int.tryParse(_leaveCutoffDayController.text.trim()),
      "notEatingRebatePolicy": _notEatingRebatePolicy,
      "partialRebatePercentage": _notEatingRebatePolicy == 'Partial'
          ? int.tryParse(_partialRebateController.text.trim())
          : null,
      "firstMonthPolicy": _firstMonthPolicy,
    };

    final notifier = ref.read(messOnboardingProvider.notifier);
    try {
      await notifier.createMess(messData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Mess created successfully!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const ManagerDashboardShell()),
            (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messOnboardingProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Mess Profile')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_stepKeys[_currentStep].currentState!.validate()) {
            final isLastStep = _currentStep == _stepKeys.length - 1;
            if (isLastStep)
              _submitForm();
            else
              setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == _stepKeys.length - 1;
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
          _buildStep(
              title: 'Basic Information',
              stepIndex: 0,
              content: Form(
                  key: _stepKeys[0],
                  child: Column(children: [
                    TextFormField(
                        controller: _messNameController,
                        decoration: const InputDecoration(
                            labelText: 'Mess Name*',
                            hintText: 'e.g., Sharma Ji\'s Kitchen'),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _managerNameController,
                        decoration: const InputDecoration(
                            labelText: 'Your Name (Manager)*'),
                        readOnly: true),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _managerContactController,
                        decoration: const InputDecoration(
                            labelText: 'Public Contact Number*',
                            prefixText: '+91 ',
                            counterText: ""),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: (v) => v!.length != 10
                            ? 'Enter a valid 10-digit number'
                            : null),
                  ]))),
          _buildStep(
              title: 'Location',
              stepIndex: 1,
              content: Form(
                  key: _stepKeys[1],
                  child: Column(children: [
                    TextFormField(
                        controller: _addressController,
                        decoration:
                            const InputDecoration(labelText: 'Full Address*'),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City*'),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Get Current Location')),
                    if (_currentPosition != null)
                      Text(
                          'Location set: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.green)),
                  ]))),
          _buildStep(
              title: 'Services & Timings',
              stepIndex: 2,
              content: Form(
                  key: _stepKeys[2],
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cuisine Type:', style: textTheme.titleMedium),
                        ...[
                          'Veg',
                          'Non-Veg',
                          'Both'
                        ].map((c) => RadioListTile<String>(
                            title: Text(c),
                            value: c,
                            groupValue: _cuisine,
                            onChanged: (v) => setState(() => _cuisine = v!))),
                        const Divider(height: 24),
                        Text('Timings:', style: textTheme.titleMedium),
                        _buildTimePickerRow(
                            'Lunch',
                            _lunchStartTime,
                            _lunchEndTime,
                            (s) => _lunchStartTime = s,
                            (e) => _lunchEndTime = e),
                        _buildTimePickerRow(
                            'Dinner',
                            _dinnerStartTime,
                            _dinnerEndTime,
                            (s) => _dinnerStartTime = s,
                            (e) => _dinnerEndTime = e),
                      ]))),
          _buildStep(
              title: 'Pricing',
              stepIndex: 3,
              content: Form(
                  key: _stepKeys[3],
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer Types Accepted:',
                            style: textTheme.titleMedium),
                        ...['Both', 'Monthly Only', 'Daily Only'].map((st) =>
                            RadioListTile<String>(
                                title: Text(st),
                                value: st,
                                groupValue: _serviceType,
                                onChanged: (v) =>
                                    setState(() => _serviceType = v!))),
                        if (_serviceType != 'Monthly Only') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                              controller: _dailyThaliRateController,
                              decoration: const InputDecoration(
                                  labelText: 'Per-Thali Rate for Daily Users*',
                                  prefixText: '₹ '),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Rate is required'
                                  : null),
                        ],
                        if (_serviceType != 'Daily Only')
                          ..._buildMealPlanForms(),
                      ]))),
          _buildStep(
              title: 'Rules & Policies',
              stepIndex: 4,
              content: Form(
                  key: _stepKeys[4],
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                            controller: _rebateDaysController,
                            decoration: const InputDecoration(
                                labelText:
                                    'Min. consecutive leave days for rebate',
                                hintText: 'e.g., 3'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _leaveCutoffDayController,
                            decoration: const InputDecoration(
                                labelText:
                                    'Last day of month to apply for leave',
                                hintText: 'e.g., 26'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        const SizedBox(height: 24),
                        Text('"Not Eating" Toggle Rebate Policy:',
                            style: textTheme.titleMedium),
                        ...[
                          'None',
                          'Partial',
                          'Full'
                        ].map((p) => RadioListTile<String>(
                            title: Text(p),
                            value: p,
                            groupValue: _notEatingRebatePolicy,
                            onChanged: (v) =>
                                setState(() => _notEatingRebatePolicy = v!))),
                        if (_notEatingRebatePolicy == 'Partial')
                          TextFormField(
                              controller: _partialRebateController,
                              decoration: const InputDecoration(
                                  labelText: 'Partial Rebate Percentage',
                                  suffixText: '%'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) =>
                                  v!.isEmpty ? 'Percentage is required' : null),
                        const SizedBox(height: 24),
                        Text('First Month Billing Policy:',
                            style: textTheme.titleMedium),
                        ...['Pro-Rata', 'Pay-Per-Day'].map((p) =>
                            RadioListTile<String>(
                                title: Text(p),
                                value: p,
                                groupValue: _firstMonthPolicy,
                                onChanged: (v) =>
                                    setState(() => _firstMonthPolicy = v!))),
                      ]))),
          _buildStep(
              title: 'Review & Submit',
              stepIndex: 5,
              content: const ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text('You are all set!'),
                subtitle: Text(
                    'Please review your details in the previous steps and then click "Create Mess" to finish.'),
              )),
        ],
      ),
    );
  }

  // --- WIDGET BUILDER HELPERS ---
  Step _buildStep(
      {required String title,
      String? subtitle,
      required int stepIndex,
      required Widget content}) {
    return Step(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      isActive: _currentStep >= stepIndex,
      state: _currentStep > stepIndex ? StepState.complete : StepState.indexed,
      content: content,
    );
  }

  Widget _buildTimePickerRow(
      String label,
      TimeOfDay start,
      TimeOfDay end,
      ValueChanged<TimeOfDay> onStartChanged,
      ValueChanged<TimeOfDay> onEndChanged) {
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
      TextButton(
          onPressed: () =>
              _selectTime(context, isStart: true, isLunch: label == 'Lunch'),
          child: Text(start.format(context))),
      const Text(' to '),
      TextButton(
          onPressed: () =>
              _selectTime(context, isStart: false, isLunch: label == 'Lunch'),
          child: Text(end.format(context))),
    ]);
  }

  List<Widget> _buildMealPlanForms() {
    List<Widget> forms = [];
    for (int i = 0; i < _mealPlanForms.length; i++) {
      forms.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Form(
            key: _mealPlanForms[i].key,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Monthly Plan ${i + 1}',
                  style: Theme.of(context).textTheme.titleMedium),
              Row(children: [
                Expanded(
                    child: DropdownButtonFormField<String>(
                  value: _mealPlanForms[i].planName,
                  items: ['Full Day', 'Lunch', 'Dinner']
                      .map((String value) => DropdownMenuItem<String>(
                          value: value, child: Text(value)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _mealPlanForms[i].planName = v!),
                  decoration: const InputDecoration(labelText: 'Plan Type*'),
                )),
                if (i > 0)
                  IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () =>
                          setState(() => _mealPlanForms.removeAt(i))),
              ]),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _mealPlanForms[i].priceController,
                  decoration: const InputDecoration(
                      labelText: 'Price (per month)*', prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _mealPlanForms[i].rebateController,
                  decoration: const InputDecoration(
                      labelText: 'Rebate Rate (per day)*', prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              if (i < _mealPlanForms.length - 1) const Divider(height: 32),
            ]),
          ),
        ),
      );
    }
    forms.add(
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TextButton.icon(
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Another Monthly Plan'),
          onPressed: () =>
              setState(() => _mealPlanForms.add(MealPlanFormState())),
        ),
      ),
    );
    return forms;
  }
}
