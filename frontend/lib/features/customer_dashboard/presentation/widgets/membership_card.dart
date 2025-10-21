// lib/features/customer_dashboard/presentation/widgets/membership_card.dart

import 'package:flutter/material.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';

class MembershipCard extends StatelessWidget {
  final Membership membership;
  final VoidCallback? onTap;
  final bool isCompact;

  const MembershipCard({
    super.key,
    required this.membership,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCompact ? 1 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Mess icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: _getStatusColor(context),
                      size: isCompact ? 24 : 32,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Mess name and plan
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          membership.messName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 14 : 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          membership.mealPlan,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: isCompact ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status chip
                  _buildStatusChip(context),
                ],
              ),

              if (!isCompact) ...[
                const Divider(height: 24),

                // Details row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        context,
                        Icons.paid,
                        'Monthly Fee',
                        '₹${membership.monthlyFee.toStringAsFixed(0)}',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        context,
                        Icons.calendar_today,
                        'Joined',
                        _formatDate(membership.joinDate),
                      ),
                    ),
                    if (membership.messRating != null)
                      Expanded(
                        child: _buildInfoColumn(
                          context,
                          Icons.star,
                          'Rating',
                          membership.messRating!.toStringAsFixed(1),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        membership.status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(context),
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
      BuildContext context, IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BuildContext context) {
    switch (membership.status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
