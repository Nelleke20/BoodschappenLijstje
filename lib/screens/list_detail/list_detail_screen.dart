import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/shopping_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../widgets/category_header.dart';
import '../../widgets/list_item_tile.dart';
import 'add_item_sheet.dart';

class ListDetailScreen extends ConsumerStatefulWidget {
  final String listId;
  final String listName;

  const ListDetailScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  final _quickAddController = TextEditingController();
  bool _showQuickAdd = false;

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  Future<String?> _getCurrentUserId() async {
    final user = await ref.read(currentUserModelProvider.future);
    return user?.id;
  }

  Future<void> _quickAddItem() async {
    final name = _quickAddController.text.trim();
    if (name.isEmpty) return;

    final userId = await _getCurrentUserId();
    if (userId == null) return;

    await ref.read(shoppingListNotifierProvider.notifier).addItem(
          listId: widget.listId,
          name: name,
          addedBy: userId,
        );

    _quickAddController.clear();
  }

  Future<void> _showAddItemSheet({ShoppingItem? existingItem}) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddItemSheet(
        existingItem: existingItem,
        onSave: ({
          required name,
          required quantity,
          required unit,
          required category,
          notes,
        }) async {
          if (existingItem != null) {
            await ref
                .read(shoppingListNotifierProvider.notifier)
                .updateItem(existingItem.copyWith(
                  name: name,
                  quantity: quantity,
                  unit: unit,
                  category: category,
                  notes: notes,
                ));
          } else {
            await ref
                .read(shoppingListNotifierProvider.notifier)
                .addItem(
                  listId: widget.listId,
                  name: name,
                  addedBy: userId,
                  quantity: quantity,
                  unit: unit,
                  category: category,
                  notes: notes,
                );
          }
        },
      ),
    );
  }

  Future<void> _toggleItem(ShoppingItem item) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;

    await ref.read(shoppingListNotifierProvider.notifier).toggleItem(
          itemId: item.id,
          listId: widget.listId,
          isChecked: !item.isChecked,
          userId: userId,
        );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort_rounded),
              title: const Text('Sorteren'),
              onTap: () {
                Navigator.pop(ctx);
                _showSortOptions(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_remove_rounded),
              title: const Text('Afgevinkten verwijderen'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(shoppingListNotifierProvider.notifier)
                    .clearCheckedItems(widget.listId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_agenda_outlined),
              title: const Text('Sjabloon laden'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/templates', extra: widget.listId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_outlined),
              title: const Text('Opslaan als sjabloon'),
              onTap: () {
                Navigator.pop(ctx);
                _showSaveAsTemplate(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Sorteren op'),
        children: SortMode.values.map((mode) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(sortModeProvider.notifier).state = mode;
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  _sortIcon(mode),
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Text(_sortLabel(mode)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showSaveAsTemplate(BuildContext context) async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Opslaan als sjabloon'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Naam van het sjabloon',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                // Template save is handled in templates screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sjabloon opgeslagen!'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              }
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }

  IconData _sortIcon(SortMode mode) {
    switch (mode) {
      case SortMode.category:
        return Icons.category_outlined;
      case SortMode.dateAdded:
        return Icons.access_time_rounded;
      case SortMode.alphabetical:
        return Icons.sort_by_alpha_rounded;
      case SortMode.checkedLast:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _sortLabel(SortMode mode) {
    switch (mode) {
      case SortMode.category:
        return 'Categorie';
      case SortMode.dateAdded:
        return 'Datum toegevoegd';
      case SortMode.alphabetical:
        return 'Alfabetisch';
      case SortMode.checkedLast:
        return 'Afgevinkt onderaan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shoppingItemsProvider(widget.listId));
    final sortMode = ref.watch(sortModeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.listName),
        actions: [
          IconButton(
            icon: Icon(
              _showQuickAdd
                  ? Icons.keyboard_hide_rounded
                  : Icons.add_circle_outline_rounded,
            ),
            tooltip: 'Snel toevoegen',
            onPressed: () =>
                setState(() => _showQuickAdd = !_showQuickAdd),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick add bar
          if (_showQuickAdd)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quickAddController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _quickAddItem(),
                      decoration: InputDecoration(
                        hintText: 'Snel toevoegen...',
                        prefixIcon: const Icon(Icons.add_rounded),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _quickAddItem,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Voeg toe'),
                  ),
                ],
              ),
            ),
          // Items list
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                final sorted = sortItems(items, sortMode);

                if (sortMode == SortMode.category) {
                  return _buildCategoryGrouped(context, sorted);
                }

                return _buildFlatList(context, sorted);
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fout: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 20),
            const Text(
              'Lijst is leeg',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Voeg producten toe via de + knop of typ een naam hierboven.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrouped(
      BuildContext context, List<ShoppingItem> items) {
    final grouped = groupByCategory(items);
    final categories = grouped.keys.toList()..sort();

    // Put checked categories at the end
    final unchecked = categories
        .where((c) => grouped[c]!.any((i) => !i.isChecked))
        .toList();
    final checkedOnly = categories
        .where((c) => grouped[c]!.every((i) => i.isChecked))
        .toList();

    final orderedCategories = [...unchecked, ...checkedOnly];

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: orderedCategories.length,
      itemBuilder: (ctx, catIndex) {
        final category = orderedCategories[catIndex];
        final categoryItems = grouped[category]!;
        final checkedInCat =
            categoryItems.where((i) => i.isChecked).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryHeader(
              category: category,
              itemCount: categoryItems.length,
              checkedCount: checkedInCat,
            ),
            ...categoryItems.map((item) => _buildItemTile(item)),
          ],
        );
      },
    );
  }

  Widget _buildFlatList(BuildContext context, List<ShoppingItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: items.length,
      itemBuilder: (ctx, index) => _buildItemTile(items[index]),
    );
  }

  Widget _buildItemTile(ShoppingItem item) {
    return ListItemTile(
      key: ValueKey(item.id),
      item: item,
      addedByInitials: item.addedBy.isNotEmpty
          ? item.addedBy.substring(0, 1).toUpperCase()
          : '?',
      onToggle: () => _toggleItem(item),
      onEdit: () => _showAddItemSheet(existingItem: item),
      onDelete: () async {
        await ref
            .read(shoppingListNotifierProvider.notifier)
            .deleteItem(item.id, widget.listId);
      },
    );
  }
}
