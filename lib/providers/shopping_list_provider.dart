import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final shoppingListsProvider =
    StreamProvider.family<List<ShoppingList>, String>(
  (ref, householdId) =>
      ref.watch(firestoreServiceProvider).listsStream(householdId),
);

final archivedListsProvider =
    StreamProvider.family<List<ShoppingList>, String>(
  (ref, householdId) =>
      ref.watch(firestoreServiceProvider).archivedListsStream(householdId),
);

final shoppingItemsProvider =
    StreamProvider.family<List<ShoppingItem>, String>(
  (ref, listId) => ref.watch(firestoreServiceProvider).itemsStream(listId),
);

// Sort mode for items
enum SortMode { category, dateAdded, alphabetical, checkedLast }

final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.category);

List<ShoppingItem> sortItems(List<ShoppingItem> items, SortMode mode) {
  final sorted = List<ShoppingItem>.from(items);
  switch (mode) {
    case SortMode.category:
      sorted.sort((a, b) {
        // Unchecked first, then sort by category
        if (a.isChecked != b.isChecked) {
          return a.isChecked ? 1 : -1;
        }
        return a.category.compareTo(b.category);
      });
    case SortMode.dateAdded:
      sorted.sort((a, b) {
        if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
        return a.addedAt.compareTo(b.addedAt);
      });
    case SortMode.alphabetical:
      sorted.sort((a, b) {
        if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
        return a.name.compareTo(b.name);
      });
    case SortMode.checkedLast:
      sorted.sort((a, b) {
        if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
        return a.order.compareTo(b.order);
      });
  }
  return sorted;
}

Map<String, List<ShoppingItem>> groupByCategory(List<ShoppingItem> items) {
  final map = <String, List<ShoppingItem>>{};
  for (final item in items) {
    map.putIfAbsent(item.category, () => []).add(item);
  }
  return map;
}

class ShoppingListNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _service;

  ShoppingListNotifier(this._service) : super(const AsyncValue.data(null));

  Future<ShoppingList> createList({
    required String householdId,
    required String name,
    required String createdBy,
  }) async {
    return _service.createList(
      householdId: householdId,
      name: name,
      createdBy: createdBy,
    );
  }

  Future<ShoppingItem> addItem({
    required String listId,
    required String name,
    required String addedBy,
    double quantity = 1,
    String unit = 'stuks',
    String? category,
    String? notes,
  }) async {
    return _service.addItem(
      listId: listId,
      name: name,
      addedBy: addedBy,
      quantity: quantity,
      unit: unit,
      category: category,
      notes: notes,
    );
  }

  Future<void> toggleItem({
    required String itemId,
    required String listId,
    required bool isChecked,
    required String userId,
  }) async {
    await _service.toggleItemChecked(
      itemId: itemId,
      listId: listId,
      isChecked: isChecked,
      userId: userId,
    );
  }

  Future<void> updateItem(ShoppingItem item) async {
    await _service.updateItem(item);
  }

  Future<void> deleteItem(String itemId, String listId) async {
    await _service.deleteItem(itemId, listId);
  }

  Future<void> clearCheckedItems(String listId) async {
    await _service.clearCheckedItems(listId);
  }

  Future<void> deleteList(String listId) async {
    await _service.deleteList(listId);
  }

  Future<void> archiveList(String listId) async {
    await _service.archiveList(listId);
  }
}

final shoppingListNotifierProvider =
    StateNotifierProvider<ShoppingListNotifier, AsyncValue<void>>((ref) {
  return ShoppingListNotifier(ref.watch(firestoreServiceProvider));
});
