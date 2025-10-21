// lib/features/mess_onboarding/presentation/screens/create_mess_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mess_management_system/features/auth/presentation/providers/auth_provider.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/screens/manager_dashboard_shell.dart';
import 'package:mess_management_system/features/mess_onboarding/presentation/providers/mess_onboarding_provider.dart';

// Helper class to manage dynamic meal plan forms with controlled state
class MealPlanFormState {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController rebateController = TextEditingController();
  String planName = 'Full Day';

  void dispose() {
    priceController.dispose();
    rebateController.dispose();
  }
}

class CreateMessScreen extends ConsumerStatefulWidget {
  const CreateMessScreen({super.key});

  @override
  ConsumerState<CreateMessScreen> createState() => _CreateMessScreenState();
}

class _CreateMessScreenState extends ConsumerState<CreateMessScreen> {
  int _currentStep = 0;

  // Form keys for granular step validation
  final _stepKeys = List.generate(6, (_) => GlobalKey<FormState>());

  // Controllers for text fields
  final _messNameController = TextEditingController();
  final _managerContactController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _dailyThaliRateController = TextEditingController();
  final _specialThaliRateController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '100');
  final _rebateMinDaysController = TextEditingController(text: '4');
  final _toggleSkipRebateController = TextEditingController(text: '0');
  final _minMonthlyChargeController = TextEditingController(text: '0');
  final _leaveDeadlineController = TextEditingController(text: '22:00');

  // State variables
  String _cuisine = 'Veg';
  String _serviceType = 'Both';
  TimeOfDay _lunchStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lunchEndTime = const TimeOfDay(hour: 14, minute: 30);
  TimeOfDay _dinnerStartTime = const TimeOfDay(hour: 19, minute: 30);
  TimeOfDay _dinnerEndTime = const TimeOfDay(hour: 22, minute: 0);

  // Location and map state
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _isLoadingAddress = false;

  // Dynamic meal plans
  List<MealPlanFormState> _mealPlanForms = [MealPlanFormState()];

  @override
  void initState() {
    super.initState();
    _getCurrentLocationForMap();
  }

  @override
  void dispose() {
    _messNameController.dispose();
    _managerContactController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _dailyThaliRateController.dispose();
    _specialThaliRateController.dispose();
    _securityDepositController.dispose();
    _maxMembersController.dispose();
    _rebateMinDaysController.dispose();
    _toggleSkipRebateController.dispose();
    _minMonthlyChargeController.dispose();
    _leaveDeadlineController.dispose();
    for (var form in _mealPlanForms) {
      form.dispose();
    }
    super.dispose();
  }

  // --- Location & Map Methods ---
  Future<void> _getCurrentLocationForMap() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_selectedLocation!, 15.0);
      _reverseGeocodeLocation(_selectedLocation!);
    } catch (_) {
      // Fallback to default location if fails
      setState(() {
        _selectedLocation = LatLng(28.7041, 77.1025); // Delhi default
      });
    }
  }

  Future<void> _reverseGeocodeLocation(LatLng latLng) async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _addressController.text =
            '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}'
                .replaceAll(RegExp(r'^,\s*|,\s*$'), '');
        _cityController.text =
            place.locality ?? place.subAdministrativeArea ?? '';
      }
    } catch (_) {
      // Reverse geocoding failed; user can manually enter
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() => _selectedLocation = latLng);
    _reverseGeocodeLocation(latLng);
  }

  // --- Time Picker ---
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
          isStart ? _lunchStartTime = newTime : _lunchEndTime = newTime;
        } else {
          isStart ? _dinnerStartTime = newTime : _dinnerEndTime = newTime;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // --- Form Submission ---
  Future<void> _submitForm() async {
    // Validate all steps
    bool allValid = true;
    for (int i = 0; i < _stepKeys.length - 1; i++) {
      // Exclude review step from validation
      if (_stepKeys[i].currentState?.validate() == false) {
        allValid = false;
      }
    }

    if (!allValid) {
      _showSnackbar('Please correct errors in all steps.', isError: true);
      return;
    }

    if (_selectedLocation == null) {
      _showSnackbar('Please select mess location on the map.', isError: true);
      setState(() => _currentStep = 1);
      return;
    }

    // Build strictly typed payload
    final Map<String, dynamic> messData = {
      'name': _messNameController.text.trim(),
      'managerContact': _managerContactController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'location': {
        'type': 'Point',
        'coordinates': [
          _selectedLocation!.longitude,
          _selectedLocation!.latitude
        ],
      },
      'cuisine': _cuisine,
      'serviceType': _serviceType,
      'timings': {
        'lunch': {
          'start': _formatTimeOfDay(_lunchStartTime),
          'end': _formatTimeOfDay(_lunchEndTime),
        },
        'dinner': {
          'start': _formatTimeOfDay(_dinnerStartTime),
          'end': _formatTimeOfDay(_dinnerEndTime),
        },
      },
      'maxMembers': int.tryParse(_maxMembersController.text.trim()) ?? 100,
      'rebateMinDays': int.tryParse(_rebateMinDaysController.text.trim()) ?? 4,
      'toggleSkipRebatePercentage':
          int.tryParse(_toggleSkipRebateController.text.trim()) ?? 0,
      'minMonthlyCharge':
          double.tryParse(_minMonthlyChargeController.text.trim()) ?? 0,
      'leaveApplicationDeadlineTime': _leaveDeadlineController.text.trim(),
    };

    // Conditional: dailyThaliRate
    if (_serviceType != 'Monthly Only') {
      final rate = double.tryParse(_dailyThaliRateController.text.trim());
      if (rate != null && rate > 0) {
        messData['dailyThaliRate'] = rate;
      }
      final special = double.tryParse(_specialThaliRateController.text.trim());
      if (special != null && special > 0) {
        messData['specialThaliRate'] = special;
      }
    }

    // Conditional: mealPlans + securityDeposit
    if (_serviceType != 'Daily Only') {
      final plans = _mealPlanForms.map((form) {
        return {
          'name': form.planName,
          'priceHistory': [
            {'price': double.parse(form.priceController.text.trim())}
          ],
          'perThaliRebateRate': double.parse(form.rebateController.text.trim()),
        };
      }).toList();
      messData['mealPlans'] = plans;

      final deposit = double.tryParse(_securityDepositController.text.trim());
      if (deposit != null && deposit > 0) {
        messData['securityDeposit'] = deposit;
      }
    }

    try {
      await ref.read(messOnboardingProvider.notifier).createMess(messData);
      if (mounted) {
        _showSnackbar('Mess created successfully!', isError: false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ManagerDashboardShell()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(e.toString(), isError: true);
      }
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messOnboardingProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Mess'),
        elevation: 0,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == _stepKeys.length - 1) {
                  _submitForm();
                } else {
                  if (_stepKeys[_currentStep].currentState?.validate() ??
                      true) {
                    setState(() => _currentStep++);
                  }
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) setState(() => _currentStep--);
              },
              controlsBuilder: (context, details) {
                final isLast = _currentStep == _stepKeys.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      FilledButton.icon(
                        onPressed: details.onStepContinue,
                        icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                        label: Text(isLast ? 'Create Mess' : 'Next'),
                      ),
                      const SizedBox(width: 12),
                      if (_currentStep > 0)
                        OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                _buildStep(
                  title: 'Basic Information',
                  icon: Icons.info_outline,
                  index: 0,
                  content: _buildBasicInfoForm(),
                ),
                _buildStep(
                  title: 'Location',
                  icon: Icons.location_on_outlined,
                  index: 1,
                  content: _buildLocationForm(),
                ),
                _buildStep(
                  title: 'Services & Cuisine',
                  icon: Icons.restaurant_menu,
                  index: 2,
                  content: _buildServicesForm(),
                ),
                _buildStep(
                  title: 'Pricing',
                  icon: Icons.payments_outlined,
                  index: 3,
                  content: _buildPricingForm(),
                ),
                _buildStep(
                  title: 'Policies',
                  icon: Icons.policy_outlined,
                  index: 4,
                  content: _buildPoliciesForm(),
                ),
                _buildStep(
                  title: 'Review & Submit',
                  icon: Icons.check_circle_outline,
                  index: 5,
                  content: _buildReviewForm(),
                ),
              ],
            ),
    );
  }

  Step _buildStep({
    required String title,
    required IconData icon,
    required int index,
    required Widget content,
  }) {
    return Step(
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      isActive: _currentStep >= index,
      state: _currentStep > index ? StepState.complete : StepState.indexed,
      content: content,
    );
  }

  // --- Step 0: Basic Info ---
  Widget _buildBasicInfoForm() {
    return Form(
      key: _stepKeys[0],
      child: Column(
        children: [
          TextFormField(
            controller: _messNameController,
            decoration: const InputDecoration(
              labelText: 'Mess Name *',
              hintText: 'e.g., Sharma Ji\'s Kitchen',
              prefixIcon: Icon(Icons.store),
            ),
            validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _managerContactController,
            decoration: const InputDecoration(
              labelText: 'Public Contact Number *',
              hintText: '10-digit number',
              prefixIcon: Icon(Icons.phone),
              prefixText: '+91 ',
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) =>
                v?.length != 10 ? 'Enter valid 10-digit number' : null,
          ),
        ],
      ),
    );
  }

  // --- Step 1: Location with Map ---
  Widget _buildLocationForm() {
    return Form(
      key: _stepKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Full Address *',
              hintText: 'Street, locality',
              prefixIcon: Icon(Icons.home),
            ),
            validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City *',
              prefixIcon: Icon(Icons.location_city),
            ),
            validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap on the map to set your mess location:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (_isLoadingAddress)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation ?? LatLng(28.7041, 77.1025),
                  initialZoom: 15.0,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.mess_management_system',
                  ),
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedLocation != null)
            Text(
              'Selected: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
              style: const TextStyle(color: Colors.green, fontSize: 12),
            ),
        ],
      ),
    );
  }

  // --- Step 2: Services & Cuisine ---
  Widget _buildServicesForm() {
    return Form(
      key: _stepKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cuisine Type *',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Wrap(
            spacing: 8,
            children: ['Veg', 'Non-Veg', 'Both'].map((c) {
              return ChoiceChip(
                label: Text(c),
                selected: _cuisine == c,
                onSelected: (sel) => setState(() => _cuisine = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Service Type *',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Wrap(
            spacing: 8,
            children: ['Both', 'Monthly Only', 'Daily Only'].map((st) {
              return ChoiceChip(
                label: Text(st),
                selected: _serviceType == st,
                onSelected: (sel) => setState(() => _serviceType = st),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Operating Hours',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildTimeRow('Lunch', _lunchStartTime, _lunchEndTime, true),
          const SizedBox(height: 8),
          _buildTimeRow('Dinner', _dinnerStartTime, _dinnerEndTime, false),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
      String label, TimeOfDay start, TimeOfDay end, bool isLunch) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        OutlinedButton.icon(
          onPressed: () =>
              _selectTime(context, isStart: true, isLunch: isLunch),
          icon: const Icon(Icons.access_time, size: 16),
          label: Text(_formatTimeOfDay(start)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('to'),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              _selectTime(context, isStart: false, isLunch: isLunch),
          icon: const Icon(Icons.access_time, size: 16),
          label: Text(_formatTimeOfDay(end)),
        ),
      ],
    );
  }

  // --- Step 3: Pricing ---
  Widget _buildPricingForm() {
    final includesDaily = _serviceType != 'Monthly Only';
    final includesMonthly = _serviceType != 'Daily Only';

    return Form(
      key: _stepKeys[3],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (includesDaily) ...[
            TextFormField(
              controller: _dailyThaliRateController,
              decoration: const InputDecoration(
                labelText: 'Daily Thali Rate *',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.restaurant),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  (v?.isEmpty ?? true) ? 'Required for daily service' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialThaliRateController,
              decoration: const InputDecoration(
                labelText: 'Special Thali Rate (optional)',
                prefixText: '₹ ',
                hintText: 'Leave empty if none',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
          ],
          if (includesMonthly) ...[
            const Text('Monthly Plans *',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._buildMealPlanForms(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _securityDepositController,
              decoration: const InputDecoration(
                labelText: 'Security Deposit (optional)',
                prefixText: '₹ ',
                hintText: '0 if none',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMealPlanForms() {
    List<Widget> forms = [];
    for (int i = 0; i < _mealPlanForms.length; i++) {
      forms.add(Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _mealPlanForms[i].key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Plan ${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (i > 0)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            setState(() => _mealPlanForms.removeAt(i)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _mealPlanForms[i].planName,
                  decoration: const InputDecoration(labelText: 'Plan Type *'),
                  items: ['Full Day', 'Lunch', 'Dinner']
                      .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _mealPlanForms[i].planName = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mealPlanForms[i].priceController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Price *',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mealPlanForms[i].rebateController,
                  decoration: const InputDecoration(
                    labelText: 'Per-Thali Rebate Rate *',
                    prefixText: '₹ ',
                    hintText: 'Used for leave rebates',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
      ));
    }
    forms.add(
      OutlinedButton.icon(
        onPressed: () =>
            setState(() => _mealPlanForms.add(MealPlanFormState())),
        icon: const Icon(Icons.add),
        label: const Text('Add Another Plan'),
      ),
    );
    return forms;
  }

  // --- Step 4: Policies ---
  Widget _buildPoliciesForm() {
    return Form(
      key: _stepKeys[4],
      child: Column(
        children: [
          TextFormField(
            controller: _maxMembersController,
            decoration: const InputDecoration(
              labelText: 'Max Members',
              hintText: 'Default: 100',
              prefixIcon: Icon(Icons.group),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rebateMinDaysController,
            decoration: const InputDecoration(
              labelText: 'Min. Consecutive Leave Days for Rebate',
              hintText: 'Default: 4',
              prefixIcon: Icon(Icons.event_busy),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _toggleSkipRebateController,
            decoration: const InputDecoration(
              labelText: 'Toggle Meal Skip Rebate (%)',
              hintText: '0-100, 0 = no rebate',
              prefixIcon: Icon(Icons.toggle_off),
              suffixText: '%',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              final val = int.tryParse(v ?? '');
              if (val == null || val < 0 || val > 100) return 'Must be 0-100';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _minMonthlyChargeController,
            decoration: const InputDecoration(
              labelText: 'Min. Monthly Charge',
              hintText: 'Minimum bill if customer uses less',
              prefixText: '₹ ',
              prefixIcon: Icon(Icons.payment),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _leaveDeadlineController,
            decoration: const InputDecoration(
              labelText: 'Leave Application Deadline (HH:MM)',
              hintText: 'e.g., 22:00',
              prefixIcon: Icon(Icons.schedule),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              final parts = v.split(':');
              if (parts.length != 2) return 'Use HH:MM format';
              final h = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              if (h == null ||
                  m == null ||
                  h < 0 ||
                  h > 23 ||
                  m < 0 ||
                  m > 59) {
                return 'Invalid time';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // --- Step 5: Review & Submit ---
  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _reviewItem('Mess Name', _messNameController.text),
        _reviewItem('Contact', '+91 ${_managerContactController.text}'),
        _reviewItem('Address', _addressController.text),
        _reviewItem('City', _cityController.text),
        _reviewItem('Cuisine', _cuisine),
        _reviewItem('Service Type', _serviceType),
        if (_serviceType != 'Monthly Only')
          _reviewItem('Daily Rate', '₹${_dailyThaliRateController.text}'),
        if (_serviceType != 'Daily Only') ...[
          const Divider(height: 24),
          const Text('Monthly Plans:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          for (var plan in _mealPlanForms)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text(
                '${plan.planName}: ₹${plan.priceController.text}/month (Rebate: ₹${plan.rebateController.text}/thali)',
              ),
            ),
        ],
        const Divider(height: 24),
        _reviewItem('Max Members', _maxMembersController.text),
        _reviewItem('Min Leave Days for Rebate', _rebateMinDaysController.text),
        _reviewItem(
            'Toggle Skip Rebate', '${_toggleSkipRebateController.text}%'),
        _reviewItem(
            'Min Monthly Charge', '₹${_minMonthlyChargeController.text}'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All set! Tap "Create Mess" to finalize.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}
