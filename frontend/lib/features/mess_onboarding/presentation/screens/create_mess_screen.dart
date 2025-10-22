// lib/features/mess_onboarding/presentation/screens/create_mess_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/screens/manager_dashboard_shell.dart';
import 'package:mess_management_system/features/mess_onboarding/presentation/providers/mess_onboarding_provider.dart';

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
  ConsumerState createState() => _CreateMessScreenState();
}

class _CreateMessScreenState extends ConsumerState<CreateMessScreen> {
  int _currentStep = 0;
  final _stepKeys = List.generate(6, (_) => GlobalKey<FormState>());

  // Text controllers
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

  // UI state
  String _cuisine = 'Veg';
  String _serviceType = 'Both'; // Only 'Both' or 'Monthly Only'
  TimeOfDay _lunchStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lunchEndTime = const TimeOfDay(hour: 14, minute: 30);
  TimeOfDay _dinnerStartTime = const TimeOfDay(hour: 19, minute: 30);
  TimeOfDay _dinnerEndTime = const TimeOfDay(hour: 22, minute: 0);

  // Map state
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _isLoadingAddress = false;
  final TextEditingController _searchController = TextEditingController();

  // Dynamic plans
  final List<MealPlanFormState> _mealPlanForms = [MealPlanFormState()];

  @override
  void initState() {
    super.initState();
    _initLocation();
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
    _searchController.dispose();
    for (final f in _mealPlanForms) f.dispose();
    super.dispose();
  }

  // Location init
  Future<void> _initLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return _fallbackDelhi();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _fallbackDelhi();
      }
      if (permission == LocationPermission.deniedForever)
        return _fallbackDelhi();
      final pos = await Geolocator.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _selectedLocation = latLng);
      _mapController.move(latLng, 15);
      await _reverseGeocode(latLng);
    } catch (_) {
      _fallbackDelhi();
    }
  }

  void _fallbackDelhi() {
    final latLng = const LatLng(28.7041, 77.1025);
    setState(() => _selectedLocation = latLng);
    _mapController.move(latLng, 12);
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _addressController.text = [
          p.street,
          p.subLocality,
          p.locality,
        ].where((s) => (s ?? '').toString().trim().isNotEmpty).join(', ');
        _cityController.text = p.locality ?? p.subAdministrativeArea ?? '';
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  void _onMapTap(TapPosition _, LatLng latLng) {
    setState(() => _selectedLocation = latLng);
    _reverseGeocode(latLng);
  }

  Future<void> _pickTime({required bool lunch, required bool start}) async {
    final initial = lunch
        ? (start ? _lunchStartTime : _lunchEndTime)
        : (start ? _dinnerStartTime : _dinnerEndTime);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (lunch) {
          start ? _lunchStartTime = picked : _lunchEndTime = picked;
        } else {
          start ? _dinnerStartTime = picked : _dinnerEndTime = picked;
        }
      });
    }
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    // Validate forms except review
    for (int i = 0; i < _stepKeys.length - 1; i++) {
      final ok = _stepKeys[i].currentState?.validate() ?? true;
      if (!ok) {
        _snack('Please fix errors in step ${i + 1}.', error: true);
        setState(() => _currentStep = i);
        return;
      }
    }
    if (_selectedLocation == null) {
      _snack('Please select mess location on the map.', error: true);
      setState(() => _currentStep = 1);
      return;
    }

    final includesDaily = _serviceType == 'Both';
    final Map<String, dynamic> payload = {
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
        'lunch': {'start': _hhmm(_lunchStartTime), 'end': _hhmm(_lunchEndTime)},
        'dinner': {
          'start': _hhmm(_dinnerStartTime),
          'end': _hhmm(_dinnerEndTime)
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

    if (includesDaily) {
      final rate = double.tryParse(_dailyThaliRateController.text.trim());
      if (rate == null || rate <= 0) {
        _snack('Daily Thali Rate is required for Both.', error: true);
        setState(() => _currentStep = 3);
        return;
      }
      payload['dailyThaliRate'] = rate;
      final special = double.tryParse(_specialThaliRateController.text.trim());
      if (special != null && special > 0) payload['specialThaliRate'] = special;
    }

    // Monthly plans are required for both service types
    final plans = <Map<String, dynamic>>[];
    for (final f in _mealPlanForms) {
      final price = double.tryParse(f.priceController.text.trim());
      final rebate = double.tryParse(f.rebateController.text.trim());
      if (price == null || price <= 0 || rebate == null || rebate < 0) {
        _snack('Please fill valid plan price and rebate.', error: true);
        setState(() => _currentStep = 3);
        return;
      }
      plans.add({
        'name': f.planName,
        'priceHistory': [
          {'price': price}
        ],
        'perThaliRebateRate': rebate,
      });
    }
    if (plans.isEmpty) {
      _snack('Add at least one monthly plan.', error: true);
      setState(() => _currentStep = 3);
      return;
    }
    payload['mealPlans'] = plans;
    final deposit = double.tryParse(_securityDepositController.text.trim());
    if (deposit != null && deposit > 0) payload['securityDeposit'] = deposit;

    try {
      await ref.read(messOnboardingProvider.notifier).createMess(payload);
      if (!mounted) return;
      _snack('Mess created successfully!', error: false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ManagerDashboardShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString(), error: true);
    }
  }

  void _snack(String msg, {required bool error}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: error ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messOnboardingProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Mess'),
        elevation: 0,
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _initLocation,
        icon: const Icon(Icons.my_location),
        label: const Text('Use my location'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == _stepKeys.length - 1) {
                  _submit();
                } else if (_stepKeys[_currentStep].currentState?.validate() ??
                    true) {
                  setState(() => _currentStep++);
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
                            child: const Text('Back')),
                    ],
                  ),
                );
              },
              steps: [
                _step('Basic Information', Icons.info_outline, 0, _basicInfo()),
                _step('Location', Icons.location_on_outlined, 1, _location()),
                _step('Services & Cuisine', Icons.restaurant_menu, 2,
                    _services()),
                _step('Pricing', Icons.payments_outlined, 3, _pricing()),
                _step('Policies', Icons.policy_outlined, 4, _policies()),
                _step('Review & Submit', Icons.check_circle_outline, 5,
                    _review()),
              ],
            ),
    );
  }

  Step _step(String title, IconData icon, int index, Widget content) {
    return Step(
      title: Row(children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(title)
      ]),
      isActive: _currentStep >= index,
      state: _currentStep > index ? StepState.complete : StepState.indexed,
      content: content,
    );
  }

  // Step 0
  Widget _basicInfo() {
    return Form(
      key: _stepKeys[0],
      child: Column(children: [
        const SizedBox(height: 5),
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
          validator: (v) => (v == null || !RegExp(r'^\d{10}$').hasMatch(v))
              ? 'Enter valid 10-digit number'
              : null,
        ),
      ]),
    );
  }

  // Step 1
  Widget _location() {
    return Form(
      key: _stepKeys[1],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 5),
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
              labelText: 'City *', prefixIcon: Icon(Icons.location_city)),
          validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        const Text('Tap on the map to set your mess location:',
            style: TextStyle(fontWeight: FontWeight.w500)),
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
                initialCenter:
                    _selectedLocation ?? const LatLng(28.7041, 77.1025),
                initialZoom: 15.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mess_management_system',
                ),
                if (_selectedLocation != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 40),
                    ),
                  ]),
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
      ]),
    );
  }

  // Step 2
  Widget _services() {
    return Form(
      key: _stepKeys[2],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Cuisine Type *',
            style: TextStyle(fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 8,
          children: ['Veg', 'Non-Veg', 'Both']
              .map((c) => ChoiceChip(
                  label: Text(c),
                  selected: _cuisine == c,
                  onSelected: (_) => setState(() => _cuisine = c)))
              .toList(),
        ),
        const SizedBox(height: 24),
        const Text('Service Type *',
            style: TextStyle(fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 8,
          children: ['Both', 'Monthly Only']
              .map((st) => ChoiceChip(
                  label: Text(st),
                  selected: _serviceType == st,
                  onSelected: (_) => setState(() => _serviceType = st)))
              .toList(),
        ),
        const SizedBox(height: 24),
        const Text('Operating Hours',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _timeRow('Lunch', _lunchStartTime, _lunchEndTime, true),
        const SizedBox(height: 8),
        _timeRow('Dinner', _dinnerStartTime, _dinnerEndTime, false),
      ]),
    );
  }

  Widget _timeRow(String label, TimeOfDay start, TimeOfDay end, bool lunch) {
    return Row(children: [
      Expanded(child: Text(label)),
      OutlinedButton.icon(
        onPressed: () => _pickTime(lunch: lunch, start: true),
        icon: const Icon(Icons.access_time, size: 16),
        label: Text(_hhmm(start)),
      ),
      const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8), child: Text('to')),
      OutlinedButton.icon(
        onPressed: () => _pickTime(lunch: lunch, start: false),
        icon: const Icon(Icons.access_time, size: 16),
        label: Text(_hhmm(end)),
      ),
    ]);
  }

  // Step 3
  Widget _pricing() {
    final includesDaily = _serviceType == 'Both';
    final includesMonthly = true; // always required

    return Form(
      key: _stepKeys[3],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (includesDaily) ...[
          TextFormField(
            controller: _dailyThaliRateController,
            decoration: const InputDecoration(
                labelText: 'Daily Thali Rate *',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.restaurant)),
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
                hintText: 'Leave empty if none'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),
        ],
        if (includesMonthly) ...[
          const Text('Monthly Plans *',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._buildPlanCards(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _securityDepositController,
            decoration: const InputDecoration(
                labelText: 'Security Deposit (optional)',
                prefixText: '₹ ',
                hintText: '0 if none'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ]),
    );
  }

  List<Widget> _buildPlanCards() {
    final widgets = <Widget>[];
    for (int i = 0; i < _mealPlanForms.length; i++) {
      widgets.add(Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _mealPlanForms[i].key,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Plan ${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (i > 0)
                  IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          setState(() => _mealPlanForms.removeAt(i))),
              ]),
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
                    labelText: 'Monthly Price *', prefixText: '₹ '),
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
                    hintText: 'Used for leave rebates'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ]),
          ),
        ),
      ));
    }
    widgets.add(OutlinedButton.icon(
      onPressed: () => setState(() => _mealPlanForms.add(MealPlanFormState())),
      icon: const Icon(Icons.add),
      label: const Text('Add Another Plan'),
    ));
    return widgets;
  }

  // Step 4
  Widget _policies() {
    return Form(
      key: _stepKeys[4],
      child: Column(children: [
        const SizedBox(height: 5),
        TextFormField(
          controller: _maxMembersController,
          decoration: const InputDecoration(
              labelText: 'Max Members',
              hintText: 'Default: 100',
              prefixIcon: Icon(Icons.group)),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _rebateMinDaysController,
          decoration: const InputDecoration(
              labelText: 'Min. Consecutive Leave Days for Rebate',
              hintText: 'Default: 4',
              prefixIcon: Icon(Icons.event_busy)),
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
            final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
            if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59)
              return 'Invalid time';
            return null;
          },
        ),
      ]),
    );
  }

  // Step 5
  Widget _review() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Review Your Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      _reviewItem('Mess Name', _messNameController.text),
      _reviewItem('Contact', '+91 ${_managerContactController.text}'),
      _reviewItem('Address', _addressController.text),
      _reviewItem('City', _cityController.text),
      _reviewItem('Cuisine', _cuisine),
      _reviewItem('Service Type', _serviceType),
      if (_serviceType == 'Both')
        _reviewItem('Daily Rate', '₹${_dailyThaliRateController.text}'),
      const Divider(height: 24),
      const Text('Monthly Plans:',
          style: TextStyle(fontWeight: FontWeight.w600)),
      for (final plan in _mealPlanForms)
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8),
          child: Text(
              '${plan.planName}: ₹${plan.priceController.text}/month (Rebate: ₹${plan.rebateController.text}/thali)'),
        ),
      const Divider(height: 24),
      _reviewItem('Max Members', _maxMembersController.text),
      _reviewItem('Min Leave Days for Rebate', _rebateMinDaysController.text),
      _reviewItem('Toggle Skip Rebate', '${_toggleSkipRebateController.text}%'),
      _reviewItem('Min Monthly Charge', '₹${_minMonthlyChargeController.text}'),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8)),
        child: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 12),
          Expanded(
              child: Text('All set! Tap "Create Mess" to finalize.',
                  style: TextStyle(fontWeight: FontWeight.w500))),
        ]),
      ),
    ]);
  }

  Widget _reviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 140,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: Text(value.isEmpty ? '—' : value)),
      ]),
    );
  }
}
