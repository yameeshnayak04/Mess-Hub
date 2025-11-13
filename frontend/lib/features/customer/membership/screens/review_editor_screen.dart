// lib/features/customer/reviews/screens/review_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/reviews_providers.dart';

class ReviewEditorScreen extends ConsumerStatefulWidget {
  final String messId;
  const ReviewEditorScreen({super.key, required this.messId});

  @override
  ConsumerState createState() => _ReviewEditorScreenState();
}

class _ReviewEditorScreenState extends ConsumerState<ReviewEditorScreen> {
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final existing = await ref.read(myReviewProvider(widget.messId).future);
    if (!mounted) return;
    if (existing != null) {
      setState(() {
        _rating = (existing['rating'] as num?)?.toInt() ?? 0;
        _commentCtrl.text = (existing['comment'] as String?) ?? '';
      });
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(reviewsRepositoryProvider).upsertReview(
            messId: widget.messId,
            rating: _rating,
            comment: _commentCtrl.text.trim(),
          );

      if (!mounted) return;

      // Show feedback, then pop AFTER the snackbar closes (avoids !_debugLocked)
      final controller = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review saved')),
      );
      await controller.closed;
      if (mounted) context.pop(true);

      // Use go_router’s context.pop if available; otherwise Navigator.pop
      try {
        // ignore: use_build_context_synchronously
        context.pop(true);
      } catch (_) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to save review: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Your Review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Larger title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Rate your mess',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),

            // Stars row
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 8,
              children: List.generate(5, (i) {
                final idx = i + 1;
                final active = idx <= _rating;
                return IconButton(
                  iconSize: 32,
                  icon: Icon(active ? Icons.star : Icons.star_border,
                      color: active ? Colors.amber : Colors.grey),
                  onPressed: () => setState(() => _rating = idx),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Centered comment section
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Comment (optional)',
                            style: theme.textTheme.titleMedium),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 6,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Share your experience',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
