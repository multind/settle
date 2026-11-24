import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';

/// 收件箱顶部常驻快速收集框（规格 §7.1：只要求"写一句话"）。
class QuickCollectBar extends ConsumerStatefulWidget {
  const QuickCollectBar({super.key});

  @override
  ConsumerState<QuickCollectBar> createState() => _QuickCollectBarState();
}

class _QuickCollectBarState extends ConsumerState<QuickCollectBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _collect() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(inboxRepositoryProvider).add(rawText: text, source: TaskSource.text);
    _controller.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.collectAction)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('quick_collect_field'),
              controller: _controller,
              decoration: InputDecoration(
                hintText: l10n.quickCollectHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _collect(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('quick_collect_button'),
            icon: const Icon(Icons.add),
            tooltip: l10n.collectAction,
            onPressed: _collect,
          ),
        ],
      ),
    );
  }
}
