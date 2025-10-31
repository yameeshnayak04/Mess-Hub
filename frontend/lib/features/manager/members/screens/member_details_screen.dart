// lib/features/manager/members/screens/member_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/manager_members_providers.dart';

class MemberDetailsScreen extends ConsumerStatefulWidget {
  final String membershipId;
  final Map<String, dynamic>? membership; // optional snapshot
  const MemberDetailsScreen(
      {super.key, required this.membershipId, this.membership});

  @override
  ConsumerState<MemberDetailsScreen> createState() =>
      _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(memberDetailsProvider(widget.membershipId));
    final attendance = ref.watch(
      memberAttendanceProvider(MemberCalendarParams(
          widget.membershipId, _focused.month, _focused.year)),
    );
    final leaves = ref.watch(memberLeavesProvider(widget.membershipId));
    final bills = ref.watch(memberBillsProvider(widget.membershipId));

    return Scaffold(
      appBar: AppBar(title: const Text('Member Details')),
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: () async {
          ref.invalidate(memberDetailsProvider(widget.membershipId));
          ref.invalidate(memberAttendanceProvider(MemberCalendarParams(
              widget.membershipId, _focused.month, _focused.year)));
          ref.invalidate(memberLeavesProvider(widget.membershipId));
          ref.invalidate(memberBillsProvider(widget.membershipId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            details.when(
              loading: () => const _HeaderSkeleton(),
              error: (e, _) => _ErrorCard(
                  title: 'Member Info',
                  detail: e.toString(),
                  onRetry: () =>
                      ref.refresh(memberDetailsProvider(widget.membershipId))),
              data: (data) {
                final payload = Map<String, dynamic>.from(
                    data); // tolerate backend shape changes
                final m =
                    (payload['membership'] as Map?)?.cast<String, dynamic>() ??
                        widget.membership ??
                        {};
                final user = (m['user'] as Map?)?.cast<String, dynamic>();
                final status = (m['status'] as String?) ?? '—';
                final plan = (m['planName'] as String?) ?? '—';
                final rate = (m['billingRate'] is num)
                    ? (m['billingRate'] as num).toStringAsFixed(0)
                    : '—';
                final joined = (m['joinedDate'] is String)
                    ? DateTime.tryParse(m['joinedDate'] as String)
                    : null;
                final paymentStatus = (m['paymentStatus'] as String?) ?? '—';
                final address = (m['address'] as String?) ?? '';
                return _HeaderCard(
                  name: (user?['name'] ?? 'Unknown').toString(),
                  phone: (user?['phone'] ?? 'N/A').toString(),
                  status: status,
                  plan: plan,
                  rate: rate,
                  paymentStatus: paymentStatus,
                  joined: joined,
                  address: address,
                );
              },
            ),

            const SizedBox(height: 16),

            // Attendance
            attendance.when(
              loading: () => const _SectionLoading(title: 'Attendance'),
              error: (e, _) => _ErrorCard(
                  title: 'Attendance',
                  detail: e.toString(),
                  onRetry: () => ref.refresh(memberAttendanceProvider(
                      MemberCalendarParams(widget.membershipId, _focused.month,
                          _focused.year)))),
              data: (entries) {
                final byDate = <DateTime, Map<String, Map<String, dynamic>>>{};
// build from attendance entries
                for (final raw in entries) {
                  final e = Map<String, dynamic>.from(raw as Map);
                  final dt = DateTime.parse((e['date'] as String)).toLocal();
                  final key = DateTime(dt.year, dt.month, dt.day);
                  byDate.putIfAbsent(key, () => {});
                  final meal = (e['mealType'] as String?) ?? '';
                  if (meal.isNotEmpty) byDate[key]![meal] = e;
                }

                final leaveList = ref
                        .read(memberLeavesProvider(widget.membershipId))
                        .valueOrNull ??
                    [];
                for (final raw in leaveList) {
                  final l = Map<String, dynamic>.from(raw as Map);
                  final sd = DateTime.parse(l['startDate'] as String).toLocal();
                  final ed = DateTime.parse(l['endDate'] as String).toLocal();
                  for (DateTime d = DateTime(sd.year, sd.month, sd.day);
                      !d.isAfter(DateTime(ed.year, ed.month, ed.day));
                      d = d.add(const Duration(days: 1))) {
                    final key = DateTime(d.year, d.month, d.day);
                    byDate.putIfAbsent(key, () => {});
                    // only mark leave if not already Present/Skipped/Absent
                    void putIfFree(String meal) {
                      final s =
                          (byDate[key]![meal]?['status'] as String?) ?? '';
                      if (s.isEmpty) {
                        byDate[key]![meal] = {
                          'mealType': meal,
                          'status': 'Leave',
                          'date': d.toIso8601String()
                        };
                      }
                    }

                    putIfFree('Lunch');
                    putIfFree('Dinner');
                  }
                }

                final counts = _monthlyCounts(byDate);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Attendance',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          _CountsRow(counts: counts),
                          const SizedBox(height: 12),
                          TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focused,
                            calendarFormat: _format,
                            selectedDayPredicate: (d) =>
                                isSameDay(d, _selected),
                            onDaySelected: (sd, fd) => setState(() {
                              _selected = sd;
                              _focused = fd;
                            }),
                            onFormatChanged: (f) => setState(() => _format = f),
                            onPageChanged: (fd) =>
                                setState(() => _focused = fd),
                            headerStyle: const HeaderStyle(titleCentered: true),
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryOrange.withOpacity(0.25),
                                  shape: BoxShape.circle),
                              selectedDecoration: const BoxDecoration(
                                  color: AppTheme.primaryOrange,
                                  shape: BoxShape.circle),
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, _) {
                                final key =
                                    DateTime(date.year, date.month, date.day);
                                final meals = byDate[key];
                                if (meals == null) return null;
                                final lunch = meals['Lunch'];
                                final dinner = meals['Dinner'];
                                final children = <Widget>[];
                                if (lunch != null) {
                                  children.add(Positioned(
                                      bottom: 2,
                                      left: 20,
                                      child: _dot(_colorFor(
                                          lunch['status'] as String?))));
                                }
                                if (dinner != null) {
                                  children.add(Positioned(
                                      bottom: 2,
                                      right: 20,
                                      child: _dot(_colorFor(
                                          dinner['status'] as String?))));
                                }
                                return Stack(children: children);
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          _LegendRow(),
                          const SizedBox(height: 12),
                          _DayMeals(
                            date: _selected,
                            lunch: byDate[DateTime(_selected.year,
                                _selected.month, _selected.day)]?['Lunch'],
                            dinner: byDate[DateTime(_selected.year,
                                _selected.month, _selected.day)]?['Dinner'],
                          ),
                        ]),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Leaves
            leaves.when(
              loading: () => const _SectionLoading(title: 'Leave History'),
              error: (e, _) => _ErrorCard(
                  title: 'Leave History',
                  detail: e.toString(),
                  onRetry: () =>
                      ref.refresh(memberLeavesProvider(widget.membershipId))),
              data: (list) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Leave History',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        if (list.isEmpty)
                          Text('No leave records',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary))
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 16),
                            itemBuilder: (context, i) {
                              final l =
                                  Map<String, dynamic>.from(list[i] as Map);
                              final sd =
                                  DateTime.parse(l['startDate'] as String)
                                      .toLocal();
                              final ed = DateTime.parse(l['endDate'] as String)
                                  .toLocal();
                              final days = ed.difference(sd).inDays + 1;
                              return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '${DateFormat('MMM d, y').format(sd)} → ${DateFormat('MMM d, y').format(ed)}'),
                                    Text('$days days',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppTheme.textSecondary)),
                                  ]);
                            },
                          ),
                      ]),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment history
            bills.when(
              loading: () => const _SectionLoading(title: 'Payment History'),
              error: (e, _) => _ErrorCard(
                  title: 'Payment History',
                  detail: e.toString(),
                  onRetry: () =>
                      ref.refresh(memberBillsProvider(widget.membershipId))),
              data: (list) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment History',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        if (list.isEmpty)
                          Text('No bills yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary))
                        else
                          ListView.separated(
                            itemCount: list.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (_, __) =>
                                const Divider(height: 16),
                            itemBuilder: (context, i) {
                              final b =
                                  Map<String, dynamic>.from(list[i] as Map);
                              final month = b['month'] as int? ?? 0;
                              final year = b['year'] as int? ?? 0;
                              final amount = (b['totalAmount'] ??
                                  b['baseAmount'] ??
                                  0) as num;
                              final status =
                                  (b['status'] as String?) ?? 'Unknown';
                              final monthName = month > 0
                                  ? DateFormat('MMMM')
                                      .format(DateTime(year, month))
                                  : '-';
                              final color = _colorFor(status);
                              return Row(children: [
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('$monthName $year',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 4),
                                        Text('₹${amount.toStringAsFixed(0)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    color:
                                                        AppTheme.primaryOrange,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                      ]),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: color)),
                                  child: Text(status,
                                      style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ]);
                            },
                          ),
                      ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _monthlyCounts(
      Map<DateTime, Map<String, Map<String, dynamic>>> byDate) {
    final result = {'Present': 0, 'Skipped': 0, 'Leave': 0, 'Absent': 0};
    for (final meals in byDate.values) {
      for (final e in meals.values) {
        final s = (e['status'] as String?) ?? '';
        if (result.containsKey(s)) result[s] = result[s]! + 1;
      }
    }
    return result;
  }

  Color _colorFor(String? status) {
    switch (status) {
      case 'Present':
        return AppTheme.successGreen;
      case 'Skipped':
        return AppTheme.warningYellow;
      case 'Leave':
        return AppTheme.infoBlue;
      case 'Absent':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _dot(Color c) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// NEW: missing widget
class _CountsRow extends StatelessWidget {
  final Map<String, int> counts;
  const _CountsRow({required this.counts});

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, int v, Color c) => Column(children: [
          Text('$v',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: c, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary)),
        ]);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      stat('Present', counts['Present'] ?? 0, AppTheme.successGreen),
      stat('Skipped', counts['Skipped'] ?? 0, AppTheme.warningYellow),
      stat('Leave', counts['Leave'] ?? 0, AppTheme.infoBlue),
      stat('Absent', counts['Absent'] ?? 0, AppTheme.errorRed),
    ]);
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget dot(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle));
    return Row(children: [
      dot(AppTheme.successGreen),
      const SizedBox(width: 6),
      const Text('Present'),
      const SizedBox(width: 16),
      dot(AppTheme.warningYellow),
      const SizedBox(width: 6),
      const Text('Skipped'),
      const SizedBox(width: 16),
      dot(AppTheme.infoBlue),
      const SizedBox(width: 6),
      const Text('Leave'),
      const SizedBox(width: 16),
      dot(AppTheme.errorRed),
      const SizedBox(width: 6),
      const Text('Absent'),
      const Spacer(),
      const Icon(Icons.circle, size: 8, color: AppTheme.textSecondary),
      const SizedBox(width: 6),
    ]);
  }
}

class _DayMeals extends StatelessWidget {
  final DateTime date;
  final Map<String, dynamic>? lunch;
  final Map<String, dynamic>? dinner;
  const _DayMeals(
      {required this.date, required this.lunch, required this.dinner});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, dynamic>>[];
    if (lunch != null) items.add(lunch!);
    if (dinner != null) items.add(dinner!);

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('No entries for ${DateFormat('MMM d, y').format(date)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary)),
      );
    }

    return Column(
      children: items.map((m) {
        final mealType = (m['mealType'] as String?) ?? 'Meal';
        final status = (m['status'] as String?) ?? 'Unknown';
        final c = {
              'Present': AppTheme.successGreen,
              'Skipped': AppTheme.warningYellow,
              'Leave': AppTheme.infoBlue,
              'Absent': AppTheme.errorRed,
            }[status] ??
            AppTheme.textSecondary;
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: c.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.withOpacity(0.3))),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: c.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(
                    mealType == 'Lunch' ? Icons.wb_sunny : Icons.nightlight,
                    color: c)),
            const SizedBox(width: 12),
            Text(mealType, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(status,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: c, fontWeight: FontWeight.w600)),
          ]),
        );
      }).toList(),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();
  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                      color: AppTheme.surfaceColor, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    SizedBox(
                        height: 14,
                        width: double.infinity,
                        child: DecoratedBox(
                            decoration:
                                BoxDecoration(color: AppTheme.surfaceColor))),
                    SizedBox(height: 8),
                    SizedBox(
                        height: 12,
                        width: double.infinity,
                        child: DecoratedBox(
                            decoration:
                                BoxDecoration(color: AppTheme.surfaceColor))),
                    SizedBox(height: 8),
                    SizedBox(
                        height: 12,
                        width: 120,
                        child: DecoratedBox(
                            decoration:
                                BoxDecoration(color: AppTheme.surfaceColor))),
                  ])),
            ])));
  }
}

class _SectionLoading extends StatelessWidget {
  final String title;
  const _SectionLoading({required this.title});
  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 8),
              const SizedBox(
                  height: 160,
                  child: DecoratedBox(
                      decoration: BoxDecoration(color: AppTheme.surfaceColor))),
            ])));
  }
}

class _ErrorCard extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback onRetry;
  const _ErrorCard(
      {required this.title, required this.detail, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(detail,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.errorRed)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry')),
            ])));
  }
}

// Paste inside lib/features/manager/members/screens/member_details_screen.dart

class _HeaderCard extends StatelessWidget {
  final String name, phone, status, plan, rate, paymentStatus;
  final DateTime? joined;
  final String? address;

  const _HeaderCard({
    required this.name,
    required this.phone,
    required this.status,
    required this.plan,
    required this.rate,
    required this.paymentStatus,
    this.joined,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.infoBlue.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppTheme.infoBlue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(phone,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary)),
              if ((address ?? '').isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(address!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textSecondary)),
              ],
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _chip(
                    status,
                    status == 'Active'
                        ? AppTheme.successGreen
                        : AppTheme.textSecondary),
                _chip(plan, AppTheme.primaryOrange),
                _chip('₹$rate/mo', AppTheme.primaryOrange),
                _chip(
                    'Payment: $paymentStatus',
                    paymentStatus == 'Paid'
                        ? AppTheme.successGreen
                        : AppTheme.warningYellow),
                if (joined != null)
                  _chip('Joined: ${DateFormat('MMM d, y').format(joined!)}',
                      AppTheme.infoBlue),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c),
      ),
      child: Text(label,
          style:
              TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
