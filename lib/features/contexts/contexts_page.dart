import 'package:flutter/material.dart';
import 'package:settle_app/app/glass.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/guide/page_rule_hint.dart';

/// 情境列表流：由仓库暴露的 [ContextRepository.watchAll] 转为
/// StreamProvider，供页面响应式监听（providers.dart 仅提供仓库本身）。
final _contextsProvider = StreamProvider<List<Context>>(
  (ref) => ref.watch(contextRepositoryProvider).watchAll(),
);

/// 情境视图（验收⑤）：管理情境列表，删除时关联 Task 置空（§5.2）。
class ContextsPage extends ConsumerWidget {
  const ContextsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contexts = ref.watch(_contextsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navContexts)),
      floatingActionButton: FloatingActionButton.small(
        key: const Key('new_context_fab'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _ContextDialog(),
        ),
        child: const Icon(Icons.add),
      ),
      body: contexts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(
                child: PageRuleHint(
                  icon: Icons.place_outlined,
                  title: l10n.ruleContextsTitle,
                  message: l10n.ruleContextsMessage,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: list.length,
                itemBuilder: (context, i) => _ContextTile(context: list[i]),
              ),
      ),
    );
  }
}

class _ContextTile extends ConsumerWidget {
  const _ContextTile({required this.context});
  final Context context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
          leading: const Icon(Icons.place),
          title: Text(this.context.name),
          trailing: IconButton(
            key: Key('delete_context_${this.context.id}'),
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.delete,
            onPressed: () => _confirmDelete(context, ref, l10n),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm_delete_context'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(contextRepositoryProvider).delete(this.context.id);
    }
  }
}

class _ContextDialog extends ConsumerStatefulWidget {
  const _ContextDialog();

  @override
  ConsumerState<_ContextDialog> createState() => _ContextDialogState();
}

class _ContextDialogState extends ConsumerState<_ContextDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await ref.read(contextRepositoryProvider).create(name: name);
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
              l10n.add,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('context_name_field'),
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.taskContext),
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
                  key: const Key('context_save'),
                  onPressed: _save,
                  minimumSize: const Size(72, 40),
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
