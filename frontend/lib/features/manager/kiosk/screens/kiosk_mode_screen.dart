import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class KioskModeScreen extends ConsumerStatefulWidget {
  const KioskModeScreen({super.key});

  @override
  ConsumerState<KioskModeScreen> createState() => _KioskModeScreenState();
}

class _KioskModeScreenState extends ConsumerState<KioskModeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentMeal = 'Lunch'; // This should come from API

  // Sample data - replace with actual API data
  final List<Map<String, dynamic>> _members = [
    {'id': '1', 'name': 'Amit Singh', 'hasMarked': false},
    {'id': '2', 'name': 'Priya Sharma', 'hasMarked': false},
    {'id': '3', 'name': 'Rahul Kumar', 'hasMarked': false},
    {'id': '4', 'name': 'Sneha Patel', 'hasMarked': false},
    {'id': '5', 'name': 'Vijay Verma', 'hasMarked': false},
    {'id': '6', 'name': 'Anjali Desai', 'hasMarked': false},
  ];

  List<Map<String, dynamic>> get _filteredMembers {
    if (_searchController.text.isEmpty) {
      return _members.where((m) => !m['hasMarked']).toList();
    }
    return _members
        .where((m) =>
            !m['hasMarked'] &&
            m['name']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitDialog();
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryOrange,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kiosk Mode',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_currentMeal Time',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 32),
                          onPressed: () => _showExitDialog(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
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
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),

              // Members Grid
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: _filteredMembers.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = _filteredMembers[index];
                            return _buildMemberCard(member);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showPinDialog(member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                child: Text(
                  member['name'][0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryOrange,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                member['name'],
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppTheme.successGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'All members have marked attendance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  void _showPinDialog(Map<String, dynamic> member) {
    final pinController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Enter Kiosk PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member['name'],
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Pinput(
                controller: pinController,
                length: 4,
                obscureText: true,
                autofocus: true,
                onCompleted: (pin) async {
                  setDialogState(() => isVerifying = true);
                  await _markAttendance(member['id'], pin);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
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
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAttendance(String userId, String pin) async {
    try {
      // API call would go here
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        final member = _members.firstWhere((m) => m['id'] == userId);
        member['hasMarked'] = true;
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppTheme.successGreen,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Attendance Marked!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Kiosk Mode'),
        content: const Text('Are you sure you want to exit kiosk mode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              context.pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
