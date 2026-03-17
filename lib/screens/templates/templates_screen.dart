import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/template.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/template_provider.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If called with a listId extra, we're in "load template" mode
    final router = GoRouterState.of(context);
    final targetListId = router.extra as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          targetListId != null ? 'Sjabloon laden' : 'Sjablonen',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _TemplatesList(targetListId: targetListId),
    );
  }
}

class _TemplatesList extends ConsumerWidget {
  final String? targetListId;

  const _TemplatesList({this.targetListId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return userAsync.when(
      data: (user) {
        final templatesAsync =
            ref.watch(allTemplatesProvider(user?.householdId));

        return templatesAsync.when(
          data: (templates) {
            if (templates.isEmpty) {
              return const Center(
                child: Text('Geen sjablonen beschikbaar'),
              );
            }

            final defaults =
                templates.where((t) => t.isDefault).toList();
            final custom = templates.where((t) => !t.isDefault).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader(title: 'Standaard sjablonen'),
                ...defaults.map((t) => _TemplateCard(
                      template: t,
                      targetListId: targetListId,
                    )),
                if (custom.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionHeader(
                    title: 'Eigen sjablonen',
                    trailing: TextButton.icon(
                      onPressed: () =>
                          _confirmDeleteAll(context, ref, custom),
                      icon: const Icon(Icons.delete_sweep_outlined,
                          size: 16),
                      label: const Text('Verwijder alles'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorColor),
                    ),
                  ),
                  ...custom.map((t) => _TemplateCard(
                        template: t,
                        targetListId: targetListId,
                        showDelete: true,
                      )),
                ],
              ],
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fout: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Fout bij laden')),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref,
      List<ShoppingTemplate> templates) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alles verwijderen?'),
        content: const Text(
            'Wil je alle eigen sjablonen verwijderen? Dit kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final t in templates) {
        await ref
            .read(templateNotifierProvider.notifier)
            .deleteTemplate(t.id);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final ShoppingTemplate template;
  final String? targetListId;
  final bool showDelete;

  const _TemplateCard({
    required this.template,
    this.targetListId,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.list_alt_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${template.items.length} producten',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (showDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.errorColor),
                  onPressed: () => _confirmDelete(context, ref),
                )
              else if (targetListId != null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    if (targetListId == null) {
      // Just preview the template
      _showPreview(context);
      return;
    }

    // Load template into list
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${template.name} laden?'),
        content: Text(
            'Wil je ${template.items.length} producten toevoegen aan je lijst?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Laden'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final userModel = await ref.read(currentUserModelProvider.future);
      if (userModel == null) return;

      await ref.read(firestoreServiceProvider).addItemsFromTemplate(
            listId: targetListId!,
            items: template.items
                .map((i) => {
                      'name': i.name,
                      'category': i.category,
                      'quantity': i.quantity,
                      'unit': i.unit,
                    })
                .toList(),
            addedBy: userModel.id,
          );

      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${template.items.length} producten toegevoegd!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  void _showPreview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${template.items.length} producten',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: template.items.length,
                itemBuilder: (ctx, i) {
                  final item = template.items[i];
                  return ListTile(
                    leading: Icon(
                      AppTheme.getCategoryIcon(item.category),
                      color: AppTheme.getCategoryColor(item.category),
                    ),
                    title: Text(item.name),
                    trailing: Text(
                      '${item.quantity.toInt()} ${item.unit}',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sjabloon verwijderen?'),
        content: Text(
            'Wil je het sjabloon "${template.name}" verwijderen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(templateNotifierProvider.notifier)
          .deleteTemplate(template.id);
    }
  }
}
