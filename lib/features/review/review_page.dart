import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:settle_app/app/glass.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/guide/page_rule_hint.dart';

/// 回顾页（验收⑥）：手动填写总结与统计并保存（每周一条）。
final _reviewsProvider = StreamProvider<List<Review>>(
  (ref) => ref.watch(reviewRepositoryProvider).watchAll(),
);

class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reviews = ref.watch(_reviewsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navReview)),
      floatingActionButton: FloatingActionButton.small(
        key: const Key('new_review_fab'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _ReviewDialog(),
        ),
        child: const Icon(Icons.add),
      ),
      body: reviews.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) => rows.isEmpty
            ? Center(
                child: PageRuleHint(
                  icon: Icons.history,
                  title: l10n.ruleReviewTitle,
                  message: l10n.ruleReviewMessage,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: rows.length,
                itemBuilder: (context, i) => _ReviewTile(review: rows[i]),
              ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  String _dateLabel() {
    final d = DateTime.fromMillisecondsSinceEpoch(review.date);
    return '${d.year}-${d.month}-${d.day}';
  }

  String? _statsLabel() {
    if (review.stats == null) return null;
    try {
      final m = jsonDecode(review.stats!) as Map<String, dynamic>;
      return 'D:${m['done']} N:${m['new']} S:${m['stalled']}';
    } on FormatException {
      return review.stats;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _statsLabel();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GlassContainer(
        color: tokens.cardSolid,
        blur: 5,
        saturate: 1.0,
        borderColor: tokens.stroke,
        borderRadius: BorderRadius.circular(AppTokens.radiusRow),
        shadow: tokens.shadowSm,
        child: ListTile(
          title: Text(_dateLabel()),
          subtitle: Text(review.summary ?? '-'),
          trailing: stats == null ? null : Text(stats),
        ),
      ),
    );
  }
}

class _ReviewDialog extends ConsumerStatefulWidget {
  const _ReviewDialog();

  @override
  ConsumerState<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<_ReviewDialog> {
  final _summary = TextEditingController();
  final _done = TextEditingController();
  final _new = TextEditingController();
  final _stalled = TextEditingController();

  @override
  void dispose() {
    _summary.dispose();
    _done.dispose();
    _new.dispose();
    _stalled.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final done = int.tryParse(_done.text.trim());
    final created = int.tryParse(_new.text.trim());
    final stalled = int.tryParse(_stalled.text.trim());
    if (done == null || created == null || stalled == null) return;
    final now = DateTime.now();
    final dayStart =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    await ref.read(reviewRepositoryProvider).create(
          date: dayStart,
          summary: _summary.text.trim().isEmpty ? null : _summary.text.trim(),
          stats: jsonEncode({'done': done, 'new': created, 'stalled': stalled}),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: GlassContainer(
        color: tokens.card,
        blur: 12,
        saturate: 1.8,
        borderColor: tokens.stroke,
        borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
        shadow: tokens.shadow,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.newReview,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('review_summary_field'),
                      controller: _summary,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: l10n.reviewSummary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('review_done_field'),
                      controller: _done,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.reviewDone),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('review_new_field'),
                      controller: _new,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.reviewNew),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('review_stalled_field'),
                      controller: _stalled,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.reviewStalled),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                GradientButton(
                  key: const Key('review_save'),
                  onPressed: _save,
                  minimumSize: const Size(72, 40),
                  child: Text(l10n.saveReview),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
