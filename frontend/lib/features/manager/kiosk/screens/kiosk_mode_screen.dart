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

class _KioskModeScreenState extends ConsumerState<KioskModeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _meal = 'Lunch'; // Default; will be set based on current time window
  bool _isWithinWindow = false;
  TimeOfDay? _start;
  TimeOfDay? _end;

  @override
  void initState() {
    super.initState();
    // Pre-compute on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromMess());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _hydrateFromMess() async {
    final mess = await ref.read(kioskMessProvider.future);
    if (mess == null) return;
    final timings = mess['timings'] as Map<String, dynamic>?;
    if (timings == null) return;

    // Determine current meal window
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
      // Not within any window; choose next upcoming window for UI
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
        !RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(hhmm))
      return null;
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
    return '${_start != null ? fmt(_start!) : '-'} to ${_end != null ? fmt(_end!) : '-'}';
  }

  @override
  Widget build(BuildContext context) {
    final mess = ref.watch(kioskMessProvider);
    final members = ref.watch(kioskActiveMembersProvider);
    final eatingNow = ref.watch(kioskMembersEatingProvider);
    final onLeave = ref.watch(kioskMembersOnLeaveProvider);
    final skipped = ref.watch(kioskMembersSkippedProvider);

    // ignore: deprecated_member_use
    return WillPopScope(
        onWillPop: () async {
          _safeExit(); // custom method below
          return false;
        },
        child: Scaffold(
          backgroundColor: AppTheme.primaryOrange,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Kiosk Mode',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('$_meal • ${_windowText()}',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16)),
                                ]),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 32),
                              onPressed: () => _confirmExit(),
                            ),
                          ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        // Meal toggle
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Lunch', label: Text('Lunch')),
                            ButtonSegment(
                                value: 'Dinner', label: Text('Dinner')),
                          ],
                          selected: {_meal},
                          onSelectionChanged: (set) {
                            setState(() {
                              _meal = set.first;
                              _isWithinWindow =
                                  _checkWithin(_meal, mess.valueOrNull);
                            });
                            _snack(
                              _isWithinWindow
                                  ? '$_meal window active'
                                  : '$_meal window not active • ${_windowText()}',
                              _isWithinWindow
                                  ? AppTheme.successGreen
                                  : AppTheme.warningYellow,
                            );
                          },
                          style: const ButtonStyle(
                              visualDensity:
                                  VisualDensity(horizontal: -2, vertical: -2)),
                        ),
                        const SizedBox(width: 12),
                        // Daily button (if supported)
                        mess.when(
                          data: (m) {
                            final supported = (m?['serviceType'] as String?) ==
                                'Both Daily & Monthly';
                            return supported
                                ? OutlinedButton.icon(
                                    onPressed: _isWithinWindow
                                        ? () => _markDaily()
                                        : () => _snack(
                                            'Daily allowed only in time window',
                                            AppTheme.warningYellow),
                                    icon: const Icon(Icons.event_available,
                                        color: Colors.white),
                                    label: const Text('Daily Log',
                                        style: TextStyle(color: Colors.white)),
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Colors.white)),
                                  )
                                : const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search member...',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.7)),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),

                // Members grid
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: members.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                  AppTheme.primaryOrange))),
                      error: (e, st) => _ErrorFeed(
                        title: 'Failed to load members',
                        detail: e.toString(),
                        onRetry: () {
                          ref.invalidate(kioskActiveMembersProvider);
                          ref.invalidate(kioskMembersEatingProvider);
                        },
                      ),
                      data: (list) {
                        final eatingUserIds = (eatingNow.valueOrNull ?? [])
                            .map((e) =>
                                (e as Map)['user']?['_id'] ?? (e)['user'] ?? '')
                            .cast<String>()
                            .toSet();

                        final leaveUserIds = (onLeave.valueOrNull ?? [])
                            .map((e) =>
                                (e as Map)['user']?['_id'] ?? (e)['user'] ?? '')
                            .cast<String>()
                            .toSet();

                        final skippedUserIds = (skipped.valueOrNull ?? [])
                            .where((e) {
                              final m = e as Map;
                              final meal = (m['mealType'] ?? '').toString();
                              return meal.isEmpty ||
                                  meal == _meal; // only current meal
                            })
                            .map((e) =>
                                (e as Map)['user']?['_id'] ?? (e)['user'] ?? '')
                            .cast<String>()
                            .toSet();

                        final q = _searchCtrl.text.trim().toLowerCase();

                        final filtered = list.where((m) {
                          final mm = m as Map;
                          final user = mm['user'] as Map?;
                          final name =
                              (user?['name'] ?? '').toString().toLowerCase();
                          final id = (user?['_id'] ?? '').toString();

                          final matchesSearch = q.isEmpty || name.contains(q);

                          // NEW: hide on-leave, skipped, and already-present members
                          final isBlocked = eatingUserIds.contains(id) ||
                              leaveUserIds.contains(id) ||
                              skippedUserIds.contains(id);

                          return matchesSearch && !isBlocked;
                        }).toList();

                        return GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.9),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final m = filtered[i] as Map;
                            final user = m['user'] as Map?;
                            final name = (user?['name'] ?? 'Unknown') as String;
                            final userId = (user?['_id'] ?? '') as String;

                            final alreadyPresent =
                                eatingUserIds.contains(userId);
                            final isLeave = leaveUserIds.contains(userId);
                            final isSkipped = skippedUserIds.contains(userId);
                            final disabled =
                                alreadyPresent || isLeave || isSkipped;

                            return Opacity(
                              opacity: disabled ? 0.5 : 1,
                              child: _MemberCard(
                                name: name,
                                onTap: () {
                                  if (alreadyPresent) {
                                    _snack('Already marked $_meal',
                                        AppTheme.infoBlue);
                                  } else if (isLeave) {
                                    _snack('On leave for $_meal',
                                        AppTheme.warningYellow);
                                  } else if (isSkipped) {
                                    _snack('Marked as Skipped for $_meal',
                                        AppTheme.warningYellow);
                                  } else {
                                    _showPinDialog(userId, name);
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void _safeExit() {
    final router = GoRouter.of(context);
    if (context.canPop()) {
      context.pop();
    } else {
      router.go(
          RouteNames.kioskLauncher); // or RouteNames.managerHome if preferred
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
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
        builder: (context, setStateDlg) => AlertDialog(
          title: const Text('Enter Kiosk PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Pinput(
                controller: pinCtrl,
                length: 4,
                obscureText: true,
                autofocus: true,
                onCompleted: (pin) async {
                  setStateDlg(() => isVerifying = true);
                  await _markMonthly(userId, pin);
                  if (mounted) Navigator.pop(context);
                },
              ),
              if (isVerifying) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'))
          ],
        ),
      ),
    );
  }

  Future<void> _markMonthly(String userId, String pin) async {
    try {
      await ref
          .read(kioskRepositoryProvider)
          .markMonthly(userId: userId, kioskPin: pin, mealType: _meal);
      _snack('Attendance marked: $_meal', AppTheme.successGreen);
      ref.invalidate(kioskMembersEatingProvider);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), AppTheme.errorRed);
    }
  }

  Future<void> _confirmExit() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit Kiosk Mode'),
        content: const Text('Are you sure you want to exit kiosk mode?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Exit')),
        ],
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

class _MemberCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _MemberCard({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppTheme.primaryOrange,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ]),
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
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_outline,
            size: 80, color: AppTheme.successGreen),
        const SizedBox(height: 16),
        Text(message, style: Theme.of(context).textTheme.titleLarge),
      ]),
    );
  }
}

class _ErrorFeed extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback onRetry;
  const _ErrorFeed(
      {required this.title, required this.detail, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(detail,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ]),
      ),
    );
  }
}
