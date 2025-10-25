import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';

class MenuEditorScreen extends ConsumerStatefulWidget {
  const MenuEditorScreen({super.key});

  @override
  ConsumerState<MenuEditorScreen> createState() => _MenuEditorScreenState();
}

class _MenuEditorScreenState extends ConsumerState<MenuEditorScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<TextEditingController> _lunchControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final List<TextEditingController> _dinnerControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMenuForDate(_selectedDay!);
  }

  @override
  void dispose() {
    for (var controller in _lunchControllers) {
      controller.dispose();
    }
    for (var controller in _dinnerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadMenuForDate(DateTime date) {
    // Load menu from API
    // For now, setting sample data
    _lunchControllers[0].text = 'Dal Tadka';
    _lunchControllers[1].text = 'Paneer Curry';
    _lunchControllers[2].text = 'Roti';
    _lunchControllers[3].text = 'Rice';

    _dinnerControllers[0].text = 'Chole';
    _dinnerControllers[1].text = 'Aloo Gobi';
    _dinnerControllers[2].text = 'Roti';
    _dinnerControllers[3].text = 'Rice';
  }

  Future<void> _saveMenu() async {
    setState(() => _isSaving = true);

    try {
      // API call would go here
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save menu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Editor'),
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadMenuForDate(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.secondaryOrange,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
            ),
          ),

          // Menu Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu for ${DateFormat('MMMM d, y').format(_selectedDay!)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),

                  // Lunch Section
                  _buildMealSection('Lunch', Icons.wb_sunny, _lunchControllers),
                  const SizedBox(height: 24),

                  // Dinner Section
                  _buildMealSection(
                      'Dinner', Icons.nightlight, _dinnerControllers),
                  const SizedBox(height: 24),

                  // Save Button
                  PrimaryButton(
                    text: 'Save Menu',
                    onPressed: _saveMenu,
                    isLoading: _isSaving,
                    icon: Icons.save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(
    String title,
    IconData icon,
    List<TextEditingController> controllers,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryOrange),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(
              controllers.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[index],
                  decoration: InputDecoration(
                    labelText: 'Item ${index + 1}',
                    hintText: 'Enter menu item',
                    suffixIcon: controllers[index].text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                controllers[index].clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
