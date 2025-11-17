// lib/features/manager/members/screens/members_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/manager_members_providers.dart';
import 'package:flutter/services.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
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

  Future<void> _approveDiscontinue(String id) async {
    try {
      await ref.read(managerMembersRepositoryProvider).approveDiscontinue(id);
      if (!context.mounted) return;
      _showSnackBar('Membership discontinued successfully');
      ref.invalidate(membersByStatusProvider('Active'));
      ref.invalidate(membersByStatusProvider('Inactive'));
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar('Failed: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
    }
  }

  Future<void> _rejectDiscontinue(String id) async {
    try {
      await ref.read(managerMembersRepositoryProvider).rejectDiscontinue(id);
      if (!context.mounted) return;
      _showSnackBar('Discontinuation request rejected');
      ref.invalidate(membersByStatusProvider('Active'));
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar('Failed: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
    }
  }

  Future<void> _approve(String id) async {
    try {
      await ref.read(managerMembersRepositoryProvider).approveMembership(id);
      if (!context.mounted) return;
      _showSnackBar('Member approved successfully');
      ref.invalidate(pendingMembersProvider);
      ref.invalidate(membersByStatusProvider('Active'));
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar('Failed: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
    }
  }

  Future<void> _reject(String id) async {
    try {
      await ref.read(managerMembersRepositoryProvider).rejectMembership(id);
      if (!context.mounted) return;
      _showSnackBar('Member rejected');
      ref.invalidate(pendingMembersProvider);
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar('Failed: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingMembersProvider);
    final active = ref.watch(membersByStatusProvider('Active'));
    final inactive = ref.watch(membersByStatusProvider('Inactive'));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Members',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage membership requests',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () {
                              ref.invalidate(pendingMembersProvider);
                              ref.invalidate(membersByStatusProvider('Active'));
                              ref.invalidate(
                                  membersByStatusProvider('Inactive'));
                              _showSnackBar('Refreshing...');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                        controller: _searchController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search members...',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.primaryOrange,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value.toLowerCase());
                        },
                      ),
                    ),
                  ),

                  // Modern Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _controller,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      indicator: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Pending'),
                        Tab(text: 'Active'),
                        Tab(text: 'Inactive'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: [
                  // Pending Tab
                  pending.when(
                    loading: () => _buildLoadingState(),
                    error: (e, st) => _ErrorRetry(
                      message: 'Failed to load pending members',
                      detail: e.toString(),
                      onRetry: () => ref.refresh(pendingMembersProvider),
                    ),
                    data: (pendingListRaw) {
                      final pendingList =
                          (pendingListRaw as List).cast<Map<String, dynamic>>();

                      return active.when(
                        loading: () => _buildLoadingState(),
                        error: (e, st) => _ErrorRetry(
                          message: 'Failed to load discontinuation requests',
                          detail: e.toString(),
                          onRetry: () =>
                              ref.refresh(membersByStatusProvider('Active')),
                        ),
                        data: (activeListRaw) {
                          final activeList = (activeListRaw as List)
                              .cast<Map<String, dynamic>>();
                          final discontinueList = activeList
                              .where((m) => m['leaveRequested'] == true)
                              .toList();

                          return _PendingCombinedList(
                            joinRequests: pendingList,
                            discontinueRequests: discontinueList,
                            searchQuery: _searchQuery,
                            onApproveJoin: _approve,
                            onRejectJoin: _reject,
                            onApproveDiscontinue: _approveDiscontinue,
                            onRejectDiscontinue: _rejectDiscontinue,
                          );
                        },
                      );
                    },
                  ),

                  // Active Tab
                  active.when(
                    loading: () => _buildLoadingState(),
                    error: (e, st) => _ErrorRetry(
                      message: 'Failed to load active members',
                      detail: e.toString(),
                      onRetry: () =>
                          ref.refresh(membersByStatusProvider('Active')),
                    ),
                    data: (list) => _MemberList(
                      list: (list as List).cast<Map<String, dynamic>>(),
                      searchQuery: _searchQuery,
                      onTap: (m) =>
                          context.push('/manager/member/${m['_id']}', extra: m),
                    ),
                  ),

                  // Inactive Tab
                  inactive.when(
                    loading: () => _buildLoadingState(),
                    error: (e, st) => _ErrorRetry(
                      message: 'Failed to load inactive members',
                      detail: e.toString(),
                      onRetry: () =>
                          ref.refresh(membersByStatusProvider('Inactive')),
                    ),
                    data: (list) => _MemberList(
                      list: (list as List).cast<Map<String, dynamic>>(),
                      searchQuery: _searchQuery,
                      onTap: (m) =>
                          context.push('/manager/member/${m['_id']}', extra: m),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
}

class _PendingCombinedList extends StatelessWidget {
  final List<Map<String, dynamic>> joinRequests;
  final List<Map<String, dynamic>> discontinueRequests;
  final String searchQuery;
  final Future<void> Function(String id) onApproveJoin;
  final Future<void> Function(String id) onRejectJoin;
  final Future<void> Function(String id) onApproveDiscontinue;
  final Future<void> Function(String id) onRejectDiscontinue;

  const _PendingCombinedList({
    required this.joinRequests,
    required this.discontinueRequests,
    required this.searchQuery,
    required this.onApproveJoin,
    required this.onRejectJoin,
    required this.onApproveDiscontinue,
    required this.onRejectDiscontinue,
  });

  @override
  Widget build(BuildContext context) {
    // Filter based on search
    final filteredJoin = joinRequests.where((m) {
      final user = m['user'];
      final name =
          user is Map ? (user['name']?.toString() ?? '').toLowerCase() : '';
      return searchQuery.isEmpty || name.contains(searchQuery);
    }).toList();

    final filteredDiscontinue = discontinueRequests.where((m) {
      final user = m['user'];
      final name =
          user is Map ? (user['name']?.toString() ?? '').toLowerCase() : '';
      return searchQuery.isEmpty || name.contains(searchQuery);
    }).toList();

    if (filteredJoin.isEmpty && filteredDiscontinue.isEmpty) {
      return _EmptyState(
        message: searchQuery.isEmpty
            ? 'No pending requests'
            : 'No members found matching "$searchQuery"',
        icon: searchQuery.isEmpty ? Icons.inbox_outlined : Icons.search_off,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (filteredJoin.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Join Requests',
            filteredJoin.length,
            Icons.person_add,
            AppTheme.infoBlue,
          ),
          const SizedBox(height: 12),
          ...filteredJoin.map((m) => _buildJoinRequestCard(context, m)),
          const SizedBox(height: 24),
        ],
        if (filteredDiscontinue.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Discontinuation Requests',
            filteredDiscontinue.length,
            Icons.exit_to_app,
            AppTheme.warningYellow,
          ),
          const SizedBox(height: 12),
          ...filteredDiscontinue.map((m) => _buildDiscontinueCard(context, m)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
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
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRequestCard(BuildContext context, Map<String, dynamic> m) {
    final user = m['user'] as Map<String, dynamic>?;
    final name = user?['name'] ?? 'Unknown';
    final phone = user?['phone'] ?? 'N/A';
    final plan = m['planName'] ?? 'Plan';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.infoBlue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.infoBlue,
                        AppTheme.infoBlue.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.infoBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warningYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.warningYellow.withOpacity(0.5),
                    ),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: AppTheme.warningYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 18,
                    color: AppTheme.primaryOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Plan: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    plan,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.errorRed.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onRejectJoin(m['_id'] as String),
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close,
                                  color: AppTheme.errorRed, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Reject',
                                style: TextStyle(
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.successGreen,
                          AppTheme.successGreen.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onApproveJoin(m['_id'] as String),
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Approve',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscontinueCard(BuildContext context, Map<String, dynamic> m) {
    final user = (m['user'] as Map?) ?? const {};
    final name = (user['name'] ?? 'Unknown') as String;
    final phone = (user['phone'] ?? 'N/A') as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warningYellow.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warningYellow,
                        AppTheme.warningYellow.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warningYellow.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppTheme.errorRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Requests permanent discontinuation',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.textSecondary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onRejectDiscontinue(m['_id'] as String),
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close,
                                  color: AppTheme.textSecondary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Reject',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.errorRed,
                          AppTheme.errorRed.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.errorRed.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onApproveDiscontinue(m['_id'] as String),
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Discontinue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberList extends StatelessWidget {
  final List<Map<String, dynamic>> list;
  final String searchQuery;
  final void Function(Map<String, dynamic>) onTap;

  const _MemberList({
    required this.list,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Filter based on search
    final filtered = list.where((m) {
      final user = m['user'] as Map<String, dynamic>?;
      final name = (user?['name'] ?? '').toString().toLowerCase();
      final phone = (user?['phone'] ?? '').toString();
      return searchQuery.isEmpty ||
          name.contains(searchQuery) ||
          phone.contains(searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return _EmptyState(
        message: searchQuery.isEmpty
            ? 'No members found'
            : 'No members found matching "$searchQuery"',
        icon: searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final m = filtered[i];
        final user = m['user'] as Map<String, dynamic>?;
        final name = user?['name'] ?? 'Unknown';
        final phone = user?['phone'] ?? 'N/A';
        final status = m['status'] as String? ?? 'Unknown';
        final color =
            status == 'Active' ? AppTheme.successGreen : AppTheme.textSecondary;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
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
              onTap: () => onTap(m),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.5)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({
    required this.message,
    this.icon = Icons.people_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppTheme.primaryOrange.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
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

class _ErrorRetry extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;

  const _ErrorRetry({
    required this.message,
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
              message,
              style: const TextStyle(
                fontSize: 18,
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
