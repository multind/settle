import 'package:flutter/material.dart';
import 'package:settle_app/app/glass.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/guide/page_rule_hint.dart';
import 'package:settle_app/features/inbox/clarify_dialog.dart';
import 'package:settle_app/features/inbox/quick_collect_bar.dart';

/// 收件箱条目流（仓库约定：普通 Provider 无 watchAll 成员，改文件级 StreamProvider）。
final _inboxItemsProvider =
    StreamProvider<List<InboxItem>>((ref) => ref.watch(inboxRepositoryProvider).watchAll());

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(_inboxItemsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navInbox)),
      body: Column(
        children: [
          const QuickCollectBar(),
          Expanded(
            child: items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (rows) => rows.isEmpty
                  ? Center(
                      child: PageRuleHint(
                        icon: Icons.inbox_outlined,
                        title: l10n.ruleInboxTitle,
                        message: l10n.ruleInboxMessage,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: rows.length,
                      itemBuilder: (context, i) => _InboxTile(item: rows[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxTile extends ConsumerWidget {
  const _InboxTile({required this.item});
  final InboxItem item;

  String _sourceLabel(AppLocalizations l10n) =>
      switch (TaskSource.fromStorage(item.source)) {
        TaskSource.text => l10n.sourceText,
        TaskSource.voice => l10n.sourceVoice,
        TaskSource.share => l10n.sourceShare,
        TaskSource.image => l10n.sourceImage,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPending = item.status == InboxStatus.pending.storage;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    final tile = ListTile(
      title: Text(item.rawText),
      subtitle: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          Chip(label: Text(_sourceLabel(l10n)), visualDensity: VisualDensity.compact),
          Chip(
            label: Text(isPending ? l10n.statusPending : l10n.statusClarified),
            visualDensity: VisualDensity.compact,
            labelStyle: TextStyle(
              color: tokens.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPending)
            GradientButton(
              key: Key('clarify_${item.id}'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ClarifyDialog(item: item),
              ),
              radius: AppTokens.radiusButton,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(l10n.clarify),
            ),
          const SizedBox(width: 4),
          IconButton(
            key: Key('delete_inbox_${item.id}'),
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.delete,
            onPressed: () => _confirmDelete(context, ref, l10n),
          ),
        ],
      ),
    );
    final card = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GlassContainer(
        color: tokens.cardSolid,
        blur: 5,
        saturate: 1.0,
        borderColor: tokens.stroke,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        shadow: tokens.shadowSm,
        child: tile,
      ),
    );
    // 完成项（已澄清）整体 55% 不透明度（预览 `.task.done`）。
    return isPending ? card : Opacity(opacity: 0.55, child: card);
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteInbox),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm_delete_inbox'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(inboxRepositoryProvider).delete(item.id);
    }
  }
}
