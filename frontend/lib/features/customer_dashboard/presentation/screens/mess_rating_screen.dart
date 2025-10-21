// lib/features/customer_dashboard/presentation/screens/mess_rating_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/customer_dashboard_provider.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';

class MessRatingScreen extends ConsumerStatefulWidget {
  final Membership membership;

  const MessRatingScreen({super.key, required this.membership});

  @override
  ConsumerState<MessRatingScreen> createState() => _MessRatingScreenState();
}

class _MessRatingScreenState extends ConsumerState<MessRatingScreen> {
  double _rating = 3.0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Mess'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mess info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.membership.messName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (widget.membership.messRating != null)
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  widget.membership.messRating!
                                      .toStringAsFixed(1),
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Rating section
            Text(
              'How would you rate this mess?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // Rating stars
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 50,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() => _rating = rating);
              },
            ),
            const SizedBox(height: 12),

            // Rating text
            Text(
              _getRatingText(_rating),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getRatingColor(_rating),
              ),
            ),
            const SizedBox(height: 32),

            // Review text field
            TextField(
              controller: _reviewController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Write a review (optional)',
                hintText: 'Share your experience with this mess...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isLoading ? null : _submitRating,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label:
                    Text(state.isLoading ? 'Submitting...' : 'Submit Rating'),
              ),
            ),

            // Error display
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating <= 1.5) return 'Poor';
    if (rating <= 2.5) return 'Fair';
    if (rating <= 3.5) return 'Good';
    if (rating <= 4.5) return 'Very Good';
    return 'Excellent';
  }

  Color _getRatingColor(double rating) {
    if (rating <= 2) return Colors.red;
    if (rating <= 3) return Colors.orange;
    if (rating <= 4) return Colors.blue;
    return Colors.green;
  }

  Future<void> _submitRating() async {
    final review =
        _reviewController.text.trim().isEmpty ? null : _reviewController.text;

    await ref
        .read(customerDashboardProvider.notifier)
        .rateMess(_rating, review);

    if (!mounted) return;

    final state = ref.read(customerDashboardProvider);
    if (state.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
