import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class MemberInfo {
  final String name;
  final String? phone;

  const MemberInfo({required this.name, this.phone});

  // Factory constructor to handle different data formats
  factory MemberInfo.fromMap(Map<String, dynamic> map) {
    // Try different possible keys for name
    final name = map['name'] as String? ??
        map['userName'] as String? ??
        map['memberName'] as String? ??
        map['user']?['name'] as String? ??
        'Unknown';

    // Try different possible keys for phone
    final phone = map['phone'] as String? ??
        map['contactPhone'] as String? ??
        map['phoneNumber'] as String? ??
        map['user']?['phone'] as String? ??
        map['user']?['contactPhone'] as String?;

    return MemberInfo(name: name, phone: phone);
  }
}

class MemberDetailDialog extends StatefulWidget {
  final String title;
  final List<MemberInfo> members;

  const MemberDetailDialog({
    super.key,
    required this.title,
    required this.members,
  });

  // Helper factory constructor to create dialog from raw data
  factory MemberDetailDialog.fromData({
    required String title,
    required List<dynamic> data,
  }) {
    final members = data.map((item) {
      if (item is Map<String, dynamic>) {
        return MemberInfo.fromMap(item);
      } else if (item is MemberInfo) {
        return item;
      } else {
        return const MemberInfo(name: 'Unknown', phone: null);
      }
    }).toList();

    return MemberDetailDialog(
      title: title,
      members: members,
    );
  }

  @override
  State<MemberDetailDialog> createState() => _MemberDetailDialogState();
}

class _MemberDetailDialogState extends State<MemberDetailDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<MemberInfo> get _filteredMembers {
    if (_searchQuery.isEmpty) return widget.members;
    return widget.members.where((member) {
      final nameLower = member.name.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      final phoneMatch = member.phone?.contains(_searchQuery) ?? false;
      return nameLower.contains(queryLower) || phoneMatch;
    }).toList();
  }

  String _formatPhoneForDisplay(String? phone) {
    if (phone == null || phone.trim().isEmpty) return 'No phone';

    String trimmedPhone = phone.trim();

    // Remove any existing country code formatting
    trimmedPhone = trimmedPhone.replaceAll(RegExp(r'[^\d+]'), '');

    // Handle different formats
    if (trimmedPhone.startsWith('+91')) {
      final digits = trimmedPhone.substring(3);
      if (digits.length == 10) {
        return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
      }
      return trimmedPhone;
    } else if (trimmedPhone.startsWith('91') && trimmedPhone.length == 12) {
      final digits = trimmedPhone.substring(2);
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    } else if (trimmedPhone.length == 10) {
      return '+91 ${trimmedPhone.substring(0, 5)} ${trimmedPhone.substring(5)}';
    }

    return trimmedPhone;
  }

  String _formatPhoneForCall(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';

    String trimmedPhone = phone.trim();

    // Remove any non-digit characters except +
    trimmedPhone = trimmedPhone.replaceAll(RegExp(r'[^\d+]'), '');

    if (trimmedPhone.startsWith('+91')) {
      return trimmedPhone;
    } else if (trimmedPhone.startsWith('91') && trimmedPhone.length == 12) {
      return '+$trimmedPhone';
    } else if (trimmedPhone.length == 10) {
      return '+91$trimmedPhone';
    }

    return trimmedPhone.startsWith('+') ? trimmedPhone : '+$trimmedPhone';
  }

  Future<void> _makeCall(String phoneNumber) async {
    try {
      final uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showSnackBar('Unable to make call', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to initiate call: ${e.toString()}',
            isError: true);
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('$label copied to clipboard', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _filteredMembers;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryOrange,
                        AppTheme.secondaryOrange
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.members.length} member${widget.members.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(context, rootNavigator: true)
                                    .pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                      if (widget.members.length > 5) ...[
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search members...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      onPressed: () =>
                                          setState(() => _searchQuery = ''),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Members List
                Flexible(
                  child: filteredMembers.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredMembers.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final member = filteredMembers[index];
                            return _buildMemberCard(member);
                          },
                        ),
                ),

                // Footer Stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        filteredMembers.length != widget.members.length
                            ? 'Showing ${filteredMembers.length} of ${widget.members.length}'
                            : 'Total: ${widget.members.length} member${widget.members.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(MemberInfo member) {
    final displayPhone = _formatPhoneForDisplay(member.phone);
    final callPhone = _formatPhoneForCall(member.phone);
    final hasValidPhone = callPhone.isNotEmpty &&
        member.phone != null &&
        member.phone!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: hasValidPhone
              ? () => _showMemberActions(member, displayPhone, callPhone)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryOrange.withOpacity(0.8),
                        AppTheme.secondaryOrange.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Member Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            hasValidPhone ? Icons.phone : Icons.phone_disabled,
                            size: 14,
                            color: hasValidPhone
                                ? AppTheme.primaryOrange
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              displayPhone,
                              style: TextStyle(
                                fontSize: 14,
                                color: hasValidPhone
                                    ? AppTheme.textSecondary
                                    : AppTheme.textSecondary.withOpacity(0.6),
                                fontWeight: hasValidPhone
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick Call Button
                if (hasValidPhone)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.teal, Color(0xFF00BFA5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _makeCall(callPhone),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 48,
              color: AppTheme.primaryOrange.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No members found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberActions(
      MemberInfo member, String displayPhone, String callPhone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Member Info Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryOrange,
                            AppTheme.secondaryOrange
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
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
                            member.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayPhone,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              _buildActionTile(
                icon: Icons.call,
                title: 'Call',
                subtitle: 'Make a phone call',
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(context);
                  _makeCall(callPhone);
                },
              ),
              _buildActionTile(
                icon: Icons.content_copy,
                title: 'Copy Phone Number',
                subtitle: 'Copy to clipboard',
                color: AppTheme.primaryOrange,
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(displayPhone, 'Phone number');
                },
              ),
              _buildActionTile(
                icon: Icons.person,
                title: 'Copy Name',
                subtitle: 'Copy to clipboard',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(member.name, 'Name');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
