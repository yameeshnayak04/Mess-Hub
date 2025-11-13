import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_commentCtrl.text.isEmpty
                ? 'Rating submitted'
                : 'Review saved'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to save review: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rate your mess',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(5, (i) {
                final idx = i + 1;
                final active = idx <= _rating;
                return IconButton(
                  icon: Icon(active ? Icons.star : Icons.star_border,
                      color: active ? Colors.amber : Colors.grey),
                  onPressed: () => setState(() => _rating = idx),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text('Comment (optional)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Share your experience'),
            ),
            const Spacer(),
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
