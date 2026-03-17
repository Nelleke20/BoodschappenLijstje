import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/shopping_list.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../utils/extensions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserModelProvider);

    return userAsync.when(
      data: (user) => _buildHome(context, user),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.refresh(currentUserModelProvider),
            child: const Text('Opnieuw proberen'),
          ),
        ),
      ),
    );
  }

  Widget _buildHome(BuildContext context, UserModel? user) {
    final householdId = user?.householdId;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Boodschappenlijstje'),
            if (householdId != null)
              Consumer(builder: (ctx, ref, _) {
                final householdAsync =
                    ref.watch(householdStreamProvider(householdId));
                return householdAsync.when(
                  data: (h) => Text(
                    h?.name ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                );
              }),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outlined),
            tooltip: 'Huishouden',
            onPressed: () => context.push('/household-settings'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Instellingen',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: householdId == null
          ? _buildNoHousehold(context)
          : _buildListView(context, householdId, user!),
      floatingActionButton: householdId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateListDialog(context, householdId, user!),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nieuwe lijst'),
            )
          : null,
    );
  }

  Widget _buildNoHousehold(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Geen huishouden',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maak een huishouden aan of sluit je aan bij een bestaand huishouden om samen boodschappenlijstjes te beheren.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/household-setup'),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Huishouden instellen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
      BuildContext context, String householdId, UserModel user) {
    final listsAsync = ref.watch(shoppingListsProvider(householdId));

    return listsAsync.when(
      data: (lists) {
        if (lists.isEmpty) {
          return _buildEmptyState(context, householdId, user);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(shoppingListsProvider(householdId)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lists.length,
            itemBuilder: (ctx, index) => _ShoppingListCard(
              list: lists[index],
              currentUserId: user.id,
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Fout: $e'),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, String householdId, UserModel user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Geen lijstjes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maak je eerste boodschappenlijstje aan via de + knop hieronder.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _showCreateListDialog(context, householdId, user),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Eerste lijst aanmaken'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateListDialog(
      BuildContext context, String householdId, UserModel user) async {
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nieuwe lijst'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Naam van de lijst',
            hintText: 'bijv. Weekboodschappen',
          ),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aanmaken'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      try {
        final list = await ref
            .read(shoppingListNotifierProvider.notifier)
            .createList(
              householdId: householdId,
              name: nameController.text.trim(),
              createdBy: user.id,
            );
        if (context.mounted) {
          context.push('/list/${list.id}', extra: list.name);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fout: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}

class _ShoppingListCard extends ConsumerWidget {
  final ShoppingList list;
  final String currentUserId;

  const _ShoppingListCard({
    required this.list,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = list.completionPercentage;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/list/${list.id}', extra: list.name),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      list.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenuAction(context, ref, value),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(Icons.archive_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Archiveren'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outlined,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Verwijderen',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${list.checkedCount}/${list.itemCount} afgevinkt',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    list.createdAt.toNlDateString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              if (list.itemCount > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0
                          ? AppTheme.primaryColor
                          : AppTheme.accentColor,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
      BuildContext context, WidgetRef ref, String action) async {
    if (action == 'archive') {
      await ref.read(shoppingListNotifierProvider.notifier).archiveList(list.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lijst gearchiveerd')),
        );
      }
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lijst verwijderen?'),
          content: Text(
              'Weet je zeker dat je "${list.name}" wilt verwijderen? Dit kan niet ongedaan worden gemaakt.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren'),
            ),
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
            .read(shoppingListNotifierProvider.notifier)
            .deleteList(list.id);
      }
    }
  }
}
