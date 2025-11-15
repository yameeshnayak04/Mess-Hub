// lib/features/manager/kiosk/screens/kiosk_mode_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_management_app/core/utils/constants.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/kiosk_providers.dart';

class KioskModeScreen extends ConsumerStatefulWidget {
  const KioskModeScreen({super.key});

  @override
  ConsumerState<KioskModeScreen> createState() => _KioskModeScreenState();
}

class _KioskModeScreenState extends ConsumerState<KioskModeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _meal = 'Lunch';
  bool _isWithinWindow = false;
  TimeOfDay? _start;
  TimeOfDay? _end;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromMess());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _hydrateFromMess() async {
    final mess = await ref.read(kioskMessProvider.future);
    if (mess == null) return;
    final timings = mess['timings'] as Map<String, dynamic>?;
    if (timings == null) return;

    final now = TimeOfDay.fromDateTime(DateTime.now());
    final lunchStart = _parse(timings['lunch']?['start'] as String?);
    final lunchEnd = _parse(timings['lunch']?['end'] as String?);
    final dinnerStart = _parse(timings['dinner']?['start'] as String?);
    final dinnerEnd = _parse(timings['dinner']?['end'] as String?);

    String meal = _meal;
    bool isWithin = false;
    TimeOfDay? s, e;

    if (lunchStart != null &&
        lunchEnd != null &&
        _inRange(now, lunchStart, lunchEnd)) {
      meal = 'Lunch';
      isWithin = true;
      s = lunchStart;
      e = lunchEnd;
    } else if (dinnerStart != null &&
        dinnerEnd != null &&
        _inRange(now, dinnerStart, dinnerEnd)) {
      meal = 'Dinner';
      isWithin = true;
      s = dinnerStart;
      e = dinnerEnd;
    } else {
      final nowMinutes = now.hour * 60 + now.minute;
      final ls =
          lunchStart != null ? lunchStart.hour * 60 + lunchStart.minute : 9999;
      final ds = dinnerStart != null
          ? dinnerStart.hour * 60 + dinnerStart.minute
          : 9999;
      if ((ls - nowMinutes).abs() < (ds - nowMinutes).abs()) {
        meal = 'Lunch';
        s = lunchStart;
        e = lunchEnd;
      } else {
        meal = 'Dinner';
        s = dinnerStart;
        e = dinnerEnd;
      }
    }

    if (!mounted) return;
    setState(() {
      _meal = meal;
      _isWithinWindow = isWithin;
      _start = s;
      _end = e;
    });
  }

  TimeOfDay? _parse(String? hhmm) {
    if (hhmm == null ||
        !RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(hhmm)) {
      return null;
    }
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _inRange(TimeOfDay t, TimeOfDay s, TimeOfDay e) {
    final tm = t.hour * 60 + t.minute;
    final sm = s.hour * 60 + s.minute;
    final em = e.hour * 60 + e.minute;
    return tm >= sm && tm <= em;
  }

  String _windowText() {
    if (_start == null || _end == null) return 'No timings found';
    final fmt = (TimeOfDay x) => x.format(context);
    return '${fmt(_start!)} - ${fmt(_end!)}';
  }

  @override
  Widget build(BuildContext context) {
    final mess = ref.watch(kioskMessProvider);
    final members = ref.watch(kioskActiveMembersProvider);
    final eatingNow = ref.watch(kioskMembersEatingProvider);
    final onLeave = ref.watch(kioskMembersOnLeaveProvider);
    final skipped = ref.watch(kioskMembersSkippedProvider);

    return WillPopScope(
      onWillPop: () async {
        _confirmExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(mess),

              // Main Content
              Expanded(
                child: members.when(
                  loading: () => _buildLoadingState(),
                  error: (e, st) => _ErrorFeed(
                    title: 'Failed to load members',
                    detail: e.toString(),
                    onRetry: () {
                      ref.invalidate(kioskActiveMembersProvider);
                      ref.invalidate(kioskMembersEatingProvider);
                    },
                  ),
                  data: (list) => _buildMembersGrid(
                    list,
                    eatingNow.valueOrNull ?? [],
                    onLeave.valueOrNull ?? [],
                    skipped.valueOrNull ?? [],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(AsyncValue<Map<String, dynamic>?> mess) {
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Kiosk Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tablet_mac,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Title and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kiosk Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isWithinWindow
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isWithinWindow
                                            ? Colors.greenAccent
                                            : Colors.orangeAccent)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isWithinWindow ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Exit Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: _confirmExit,
                    tooltip: 'Exit Kiosk Mode',
                  ),
                ),
              ],
            ),
          ),

          // Meal Info Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _meal == 'Lunch'
                              ? Icons.wb_sunny
                              : Icons.nightlight_round,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _meal,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _windowText(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Meal Toggle
                  Row(
                    children: [
                      Expanded(
                        child: _buildMealButton('Lunch', Icons.wb_sunny),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            _buildMealButton('Dinner', Icons.nightlight_round),
                      ),

                      // Daily Button
                      mess.when(
                        data: (m) {
                          final supported = (m?['serviceType'] as String?) ==
                              'Both Daily & Monthly';
                          return supported
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: _buildDailyButton(),
                                )
                              : const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search member by name...',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.primaryOrange,
                    size: 24,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealButton(String meal, IconData icon) {
    final isSelected = _meal == meal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _meal = meal;
            _isWithinWindow =
                _checkWithin(meal, ref.read(kioskMessProvider).valueOrNull);
          });
          _snack(
            _isWithinWindow
                ? '$meal window active'
                : '$meal window not active • ${_windowText()}',
            _isWithinWindow ? AppTheme.successGreen : AppTheme.warningYellow,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryOrange : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                meal,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryOrange : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.event_available, color: Colors.white, size: 22),
        onPressed: _isWithinWindow
            ? _markDaily
            : () => _snack(
                  'Daily allowed only in time window',
                  AppTheme.warningYellow,
                ),
        tooltip: 'Daily Log',
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
            'Loading members...',
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

  Widget _buildMembersGrid(
    List<dynamic> list,
    List<dynamic> eatingNow,
    List<dynamic> onLeave,
    List<dynamic> skipped,
  ) {
    final eatingUserIds = eatingNow
        .map((e) => (e as Map)['user']?['_id'] ?? (e)['user'] ?? '')
        .cast<String>()
        .toSet();

    final leaveUserIds = onLeave
        .map((e) => (e as Map)['user']?['_id'] ?? (e)['user'] ?? '')
        .cast<String>()
        .toSet();

    final skippedUserIds = skipped
        .where((e) {
          final m = e as Map;
          final meal = (m['mealType'] ?? '').toString();
          return meal.isEmpty || meal == _meal;
        })
        .map((e) => (e as Map)['user']?['_id'] ?? (e)['user'] ?? '')
        .cast<String>()
        .toSet();

    final q = _searchCtrl.text.trim().toLowerCase();

    final filtered = list.where((m) {
      final mm = m as Map;
      final user = mm['user'] as Map?;
      final name = (user?['name'] ?? '').toString().toLowerCase();
      final id = (user?['_id'] ?? '').toString();

      final matchesSearch = q.isEmpty || name.contains(q);
      final isBlocked = eatingUserIds.contains(id) ||
          leaveUserIds.contains(id) ||
          skippedUserIds.contains(id);

      return matchesSearch && !isBlocked;
    }).toList();

    if (filtered.isEmpty) {
      return _EmptyFeed(
        message: q.isEmpty
            ? 'All members have been marked'
            : 'No members found matching "$q"',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final m = filtered[i] as Map;
        final user = m['user'] as Map?;
        final name = (user?['name'] ?? 'Unknown') as String;
        final userId = (user?['_id'] ?? '') as String;

        return _ModernMemberCard(
          name: name,
          onTap: () => _showPinDialog(userId, name),
        );
      },
    );
  }

  void _safeExit() {
    final router = GoRouter.of(context);
    if (context.canPop()) {
      context.pop();
    } else {
      router.go(RouteNames.kioskLauncher);
    }
  }

  bool _checkWithin(String meal, Map<String, dynamic>? mess) {
    final t = mess?['timings'] as Map<String, dynamic>?;
    if (t == null) return false;
    final now = TimeOfDay.fromDateTime(DateTime.now());
    final s = _parse(t[meal.toLowerCase()]?['start'] as String?);
    final e = _parse(t[meal.toLowerCase()]?['end'] as String?);
    if (s == null || e == null) return false;
    setState(() {
      _start = s;
      _end = e;
    });
    return _inRange(now, s, e);
  }

  void _snack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.successGreen
                  ? Icons.check_circle
                  : color == AppTheme.errorRed
                      ? Icons.error_outline
                      : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showPinDialog(String userId, String name) async {
    if (!_isWithinWindow) {
      _snack('$_meal window not active • ${_windowText()}',
          AppTheme.warningYellow);
      return;
    }

    final pinCtrl = TextEditingController();
    bool isVerifying = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDlg) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.primaryOrange,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Enter Kiosk PIN',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Member Name
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryOrange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // PIN Input
                Pinput(
                  controller: pinCtrl,
                  length: 4,
                  obscureText: true,
                  autofocus: true,
                  defaultPinTheme: PinTheme(
                    width: 60,
                    height: 60,
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 60,
                    height: 60,
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.primaryOrange, width: 2),
                    ),
                  ),
                  onCompleted: (pin) async {
                    setStateDlg(() => isVerifying = true);
                    await _markMonthly(userId, pin);
                    if (mounted) Navigator.pop(context);
                  },
                ),

                if (isVerifying) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                      color: AppTheme.primaryOrange),
                  const SizedBox(height: 12),
                  const Text(
                    'Verifying...',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],

                const SizedBox(height: 24),

                // Cancel Button
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markMonthly(String userId, String pin) async {
    try {
      await ref.read(kioskRepositoryProvider).markMonthly(
            userId: userId,
            kioskPin: pin,
            mealType: _meal,
          );
      _snack('Attendance marked: $_meal', AppTheme.successGreen);
      ref.invalidate(kioskMembersEatingProvider);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), AppTheme.errorRed);
    }
  }

  Future<void> _confirmExit() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningYellow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.exit_to_app,
                  color: AppTheme.warningYellow,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Exit Kiosk Mode?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to exit kiosk mode?',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningYellow,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (exit == true) _safeExit();
  }

  Future<void> _markDaily() async {
    try {
      await ref.read(kioskRepositoryProvider).markDaily(mealType: _meal);
      _snack('Daily meal logged: $_meal', AppTheme.successGreen);
      ref.invalidate(kioskMembersEatingProvider);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), AppTheme.errorRed);
    }
  }
}

class _ModernMemberCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _ModernMemberCard({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryOrange,
                        AppTheme.secondaryOrange,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final String message;
  const _EmptyFeed({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppTheme.successGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorFeed extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback onRetry;

  const _ErrorFeed({
    required this.title,
    required this.detail,
    required this.onRetry,
  });

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
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
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
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
