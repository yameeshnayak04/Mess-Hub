// lib/features/manager/profile/screens/mess_profile_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import 'package:mess_management_app/core/api/dio_client_provider.dart';
import 'package:mess_management_app/features/auth/widgets/logout_action.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/mess_profile_providers.dart';

class MessProfileScreen extends ConsumerStatefulWidget {
  const MessProfileScreen({super.key});

  @override
  ConsumerState<MessProfileScreen> createState() => _MessProfileScreenState();
}

class _MessProfileScreenState extends ConsumerState<MessProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Identity (read-only)
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _serviceType = TextEditingController();
  final _cuisine = TextEditingController();

  // Editable basic fields
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _maxCapacity = TextEditingController();
  final _dailyRate = TextEditingController();

  // Rules
  final _minLeaveDays = TextEditingController();
  final _rebatePerThali = TextEditingController();
  final _skipPercent = TextEditingController();
  final _minMonthlyCharge = TextEditingController();

  // Thali / tiffin
  final _basicThali = TextEditingController();
  bool _tiffinService = false;

  // Timings
  TimeOfDay? _lunchStart;
  TimeOfDay? _lunchEnd;
  TimeOfDay? _dinnerStart;
  TimeOfDay? _dinnerEnd;

  // Plans snapshot (from backend)
  List<Map<String, dynamic>> _plans = [];

  File? _picked;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _name.dispose();
    _city.dispose();
    _serviceType.dispose();
    _cuisine.dispose();
    _address.dispose();
    _phone.dispose();
    _maxCapacity.dispose();
    _dailyRate.dispose();
    _minLeaveDays.dispose();
    _rebatePerThali.dispose();
    _skipPercent.dispose();
    _minMonthlyCharge.dispose();
    _basicThali.dispose();
    super.dispose();
  }

  TimeOfDay? _parseHHMM(String? v) {
    if (v == null || v.isEmpty) return null;
    final parts = v.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatHHMM(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime(BuildContext context, void Function(TimeOfDay) setter,
      {TimeOfDay? initial}) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryOrange,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => setter(picked));
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messAsync = ref.watch(messProfileProvider);
    final dio = ref.read(dioClientProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: messAsync.when(
          loading: () => _buildLoadingState(),
          error: (e, _) =>
              _Error(message: 'Failed to load', detail: e.toString()),
          data: (mess) {
            // One-time initialization from backend data
            if (!_initialized) {
              _name.text = (mess['messName'] ?? '').toString();
              _city.text = (mess['city'] ?? '').toString();
              _serviceType.text = (mess['serviceType'] ?? '').toString();
              _cuisine.text = (mess['cuisine'] ?? '').toString();

              _address.text = (mess['address'] ?? '').toString();
              _phone.text = (mess['contactPhone'] ?? '').toString();
              _maxCapacity.text = (mess['maxCapacity'] ?? '').toString();
              _dailyRate.text = (mess['dailyThaliRate'] ?? '').toString();

              final rules =
                  (mess['rules'] as Map?)?.cast<String, dynamic>() ?? {};
              _minLeaveDays.text =
                  (rules['minLeaveDaysForRebate'] ?? '').toString();
              _rebatePerThali.text = (rules['rebatePerThali'] ?? '').toString();
              _skipPercent.text =
                  (rules['skipAllowancePercent'] ?? '').toString();
              _minMonthlyCharge.text =
                  (rules['minMonthlyCharge'] ?? '').toString();

              _basicThali.text = (mess['basicThaliDetails'] ?? '').toString();
              _tiffinService = mess['tiffinService'] == true;

              final timings =
                  (mess['timings'] as Map?)?.cast<String, dynamic>() ?? {};
              _lunchStart = _parseHHMM(timings['lunchStart'] as String?);
              _lunchEnd = _parseHHMM(timings['lunchEnd'] as String?);
              _dinnerStart = _parseHHMM(timings['dinnerStart'] as String?);
              _dinnerEnd = _parseHHMM(timings['dinnerEnd'] as String?);

              final rawPlans = mess['plans'] as List? ?? const [];
              _plans = rawPlans
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();

              _initialized = true;
            }

            final scheduled =
                (mess['scheduledUpdates'] as Map?)?.cast<String, dynamic>() ??
                    {};
            final effective = mess['scheduledEffectiveFrom'] != null
                ? DateTime.tryParse(mess['scheduledEffectiveFrom'])
                : null;

            final imagePath = (mess['messImage'] as String?) ?? '';
            final imageUrl = dio.resolveServerUrl(imagePath);

            return Column(
              children: [
                // Modern Header with Image
                _buildHeader(context, imageUrl, mess),

                // Scheduled Updates Banner (Moved here - above tabs)
                if (scheduled.isNotEmpty || effective != null)
                  _buildScheduledBanner(context, scheduled, effective),

                // Tab Bar
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryOrange,
                    unselectedLabelColor: AppTheme.textSecondary,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(icon: Icon(Icons.info, size: 20), text: 'Basic'),
                      Tab(
                          icon: Icon(Icons.access_time, size: 20),
                          text: 'Timings'),
                      Tab(
                          icon: Icon(Icons.restaurant, size: 20),
                          text: 'Plans'),
                      Tab(icon: Icon(Icons.rule, size: 20), text: 'Rules'),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBasicTab(),
                        _buildTimingsTab(context),
                        _buildPlansTab(context),
                        _buildRulesTab(),
                      ],
                    ),
                  ),
                ),

                // Save Button
                _buildSaveButton(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryOrange.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: AppTheme.primaryOrange,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading mess profile...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String imageUrl, Map mess) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryOrange,
            AppTheme.secondaryOrange,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Bar
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mess Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage your mess details',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                LogoutAction(),
              ],
            ),
          ),

          // Profile Image & Basic Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final img = _picked?.path ?? imageUrl;
                        if (img.isEmpty) return;
                        showDialog(
                          context: context,
                          builder: (_) => _ImageViewer(imagePathOrUrl: img),
                        );
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          image: _picked != null
                              ? DecorationImage(
                                  image: FileImage(_picked!),
                                  fit: BoxFit.cover,
                                )
                              : (imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: (imageUrl.isEmpty && _picked == null)
                            ? const Icon(
                                Icons.restaurant,
                                size: 48,
                                color: AppTheme.primaryOrange,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final x = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (x != null) {
                              setState(() => _picked = File(x.path));
                            }
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _name.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on,
                        color: Colors.white.withOpacity(0.9), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _city.text,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.restaurant_menu,
                        color: Colors.white.withOpacity(0.9), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _cuisine.text,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'Identity',
          Icons.badge,
          [
            _modernReadOnlyField('Mess Name', _name, Icons.restaurant),
            _modernReadOnlyField('City', _city, Icons.location_city),
            _modernReadOnlyField(
                'Service Type', _serviceType, Icons.room_service),
            _modernReadOnlyField('Cuisine', _cuisine, Icons.restaurant_menu),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Contact & Capacity',
          Icons.contact_phone,
          [
            _modernField('Address', _address, Icons.home, TextInputType.text),
            _modernField(
                'Contact Phone', _phone, Icons.phone, TextInputType.phone),
            _modernField('Max Capacity', _maxCapacity, Icons.people,
                TextInputType.number),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Daily Rate',
          Icons.currency_rupee,
          [
            _modernField('Daily Thali Rate', _dailyRate, Icons.payments,
                TextInputType.number),
          ],
        ),
      ],
    );
  }

  Widget _buildTimingsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'Meal Timings',
          Icons.schedule,
          [
            _buildTimingCard(
              context,
              'Lunch',
              Icons.wb_sunny,
              AppTheme.warningYellow,
              _lunchStart,
              _lunchEnd,
              (t) => setState(() => _lunchStart = t),
              (t) => setState(() => _lunchEnd = t),
            ),
            const SizedBox(height: 16),
            _buildTimingCard(
              context,
              'Dinner',
              Icons.nightlight_round,
              AppTheme.primaryOrange,
              _dinnerStart,
              _dinnerEnd,
              (t) => setState(() => _dinnerStart = t),
              (t) => setState(() => _dinnerEnd = t),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlansTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'Pricing Plans',
          Icons.price_change,
          [
            if (_plans.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: AppTheme.textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No plans configured',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._plans
                  .asMap()
                  .entries
                  .map((entry) => _modernPlanCard(context, entry.key))
                  .toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildRulesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'Rebate & Leave Rules',
          Icons.rule,
          [
            _modernField('Min Leave Days for Rebate', _minLeaveDays,
                Icons.event_available, TextInputType.number),
            _modernField('Rebate per Thali', _rebatePerThali, Icons.money_off,
                TextInputType.number),
            _modernField('Skip Allowance Percent', _skipPercent, Icons.percent,
                TextInputType.number),
            _modernField('Min Monthly Charge', _minMonthlyCharge,
                Icons.attach_money, TextInputType.number),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Thali Details',
          Icons.dinner_dining,
          [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _tiffinService
                      ? AppTheme.successGreen.withOpacity(0.3)
                      : AppTheme.borderColor.withOpacity(0.3),
                ),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Tiffin Service',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _tiffinService ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                value: _tiffinService,
                activeColor: AppTheme.successGreen,
                onChanged: (v) => setState(() => _tiffinService = v),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _tiffinService
                        ? AppTheme.successGreen.withOpacity(0.1)
                        : AppTheme.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.takeout_dining,
                    color: _tiffinService
                        ? AppTheme.successGreen
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _modernField('Basic Thali Details', _basicThali, Icons.description,
                TextInputType.multiline,
                maxLines: 4),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryOrange.withOpacity(0.1),
                  AppTheme.primaryOrange.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernReadOnlyField(
      String label, TextEditingController c, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.text.isEmpty ? '-' : c.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernField(String label, TextEditingController c, IconData icon,
      TextInputType keyboard,
      {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryOrange),
          filled: true,
          fillColor: AppTheme.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppTheme.borderColor.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppTheme.borderColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.primaryOrange, width: 2),
          ),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildTimingCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    TimeOfDay? start,
    TimeOfDay? end,
    void Function(TimeOfDay) onStartPicked,
    void Function(TimeOfDay) onEndPicked,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _timeButton(
                  context,
                  'Start Time',
                  start,
                  color,
                  () => _pickTime(context, onStartPicked, initial: start),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeButton(
                  context,
                  'End Time',
                  end,
                  color,
                  () => _pickTime(context, onEndPicked, initial: end),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeButton(BuildContext context, String label, TimeOfDay? time,
      Color color, VoidCallback onTap) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(
                      time != null ? time.format(context) : '--:--',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernPlanCard(BuildContext context, int index) {
    final plan = _plans[index];
    final name = (plan['name'] ?? '').toString();
    final rate = (plan['rate'] ?? '').toString();
    final controller = TextEditingController(text: rate);

    final colors = [
      AppTheme.successGreen,
      AppTheme.infoBlue,
      AppTheme.warningYellow,
      AppTheme.primaryOrange,
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.restaurant_menu, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Name',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name.isEmpty ? 'Plan ${index + 1}' : name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Rate',
                  prefixText: '₹',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (v) => plan['rate'] = v.trim(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledBanner(
      BuildContext context, Map scheduled, DateTime? effective) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.infoBlue.withOpacity(0.15),
            AppTheme.infoBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoBlue.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.infoBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.schedule, color: AppTheme.infoBlue, size: 20),
        ),
        title: const Text(
          'Scheduled Changes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: effective != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Effective: ${DateFormat('MMM d, y').format(effective.toLocal())}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.infoBlue,
                  ),
                ),
              )
            : null,
        iconColor: AppTheme.infoBlue,
        collapsedIconColor: AppTheme.infoBlue,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: scheduled.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.infoBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${e.key}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${e.value}',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryOrange,
              AppTheme.secondaryOrange,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryOrange.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSaving ? null : () => _handleSave(context),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Saving...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final fields = <String, String>{
        'address': _address.text.trim(),
        'contactPhone': _phone.text.trim(),
        'maxCapacity': _maxCapacity.text.trim(),
        'dailyThaliRate': _dailyRate.text.trim(),
        'tiffinService': _tiffinService.toString(),
        'basicThaliDetails': _basicThali.text.trim(),
        'rules.minLeaveDaysForRebate': _minLeaveDays.text.trim(),
        'rules.rebatePerThali': _rebatePerThali.text.trim(),
        'rules.skipAllowancePercent': _skipPercent.text.trim(),
        'rules.minMonthlyCharge': _minMonthlyCharge.text.trim(),
        'timings.lunchStart': _formatHHMM(_lunchStart),
        'timings.lunchEnd': _formatHHMM(_lunchEnd),
        'timings.dinnerStart': _formatHHMM(_dinnerStart),
        'timings.dinnerEnd': _formatHHMM(_dinnerEnd),
      };

      for (var i = 0; i < _plans.length; i++) {
        final p = _plans[i];
        final id = p['_id']?.toString() ?? '$i';
        final rate = p['rate']?.toString() ?? '';
        fields['plans.$id.rate'] = rate;
      }

      MultipartFile? mf;
      if (_picked != null) {
        mf = await MultipartFile.fromFile(
          _picked!.path,
          filename: _picked!.path.split('/').last,
        );
      }

      await ref.read(messProfileUpdaterProvider)(fields, image: mf);

      if (!mounted) return;
      _showSnackBar('Changes scheduled for next month! 🎉');
      ref.invalidate(messProfileProvider);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ImageViewer extends StatelessWidget {
  final String imagePathOrUrl;
  const _ImageViewer({required this.imagePathOrUrl});

  @override
  Widget build(BuildContext context) {
    final isFile = !imagePathOrUrl.startsWith('http');
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: isFile
                    ? Image.file(File(imagePathOrUrl), fit: BoxFit.contain)
                    : Image.network(imagePathOrUrl, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message, detail;
  const _Error({required this.message, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
