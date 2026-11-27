import 'package:flutter/material.dart';
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
final _inboxItemsProvider = StreamProvider<List<InboxItem>>(
  (ref) => ref.watch(inboxRepositoryProvider).watchAll(),
);

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key, this.guide});

  final Widget? guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(_inboxItemsProvider);
    return Scaffold(
      appBar: AppBar(titleSpacing: 20, title: Text(l10n.navInbox)),
      body: Column(
        children: [
          if (guide != null) guide!,
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
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
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
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 8, end: 4),
      title: Text(item.rawText),
      subtitle: Wrap(
        spacing: 10,
        children: [
          Text(_sourceLabel(l10n), style: TextStyle(color: tokens.muted)),
          Text(
            isPending ? l10n.statusPending : l10n.statusClarified,
            style: TextStyle(color: isPending ? tokens.primary : tokens.muted),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPending)
            FilledButton.tonal(
              key: Key('clarify_${item.id}'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ClarifyDialog(item: item),
              ),
              child: Text(l10n.clarify),
            ),
          PopupMenuButton<bool>(
            key: Key('inbox_menu_${item.id}'),
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onSelected: (_) => _confirmDelete(context, ref, l10n),
            itemBuilder: (_) => [
              PopupMenuItem(
                key: Key('delete_inbox_${item.id}'),
                value: true,
                child: Text(l10n.delete),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
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
