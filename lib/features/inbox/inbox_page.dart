import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/inbox/clarify_dialog.dart';
import 'package:gtd_app/features/inbox/quick_collect_bar.dart';

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
                  ? Center(child: Text(l10n.emptyInbox))
                  : ListView.builder(
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
    return ListTile(
      title: Text(item.rawText),
      subtitle: Wrap(
        spacing: 8,
        children: [
          Chip(label: Text(_sourceLabel(l10n)), visualDensity: VisualDensity.compact),
          Chip(
            label: Text(isPending ? l10n.statusPending : l10n.statusClarified),
            visualDensity: VisualDensity.compact,
            backgroundColor: isPending ? Colors.amber.shade100 : Colors.green.shade100,
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPending)
            TextButton(
              key: Key('clarify_${item.id}'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ClarifyDialog(item: item),
              ),
              child: Text(l10n.clarify),
            ),
          IconButton(
            key: Key('delete_inbox_${item.id}'),
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.delete,
            onPressed: () => _confirmDelete(context, ref, l10n),
          ),
        ],
      ),
    );
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
