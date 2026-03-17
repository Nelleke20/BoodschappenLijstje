import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../config/constants.dart';
import '../utils/category_helper.dart';
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Shopping Lists ──────────────────────────────────────────────────────────

  Stream<List<ShoppingList>> listsStream(String householdId) {
    return _firestore
        .collection(AppConstants.shoppingListsCollection)
        .where('householdId', isEqualTo: householdId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ShoppingList.fromFirestore(doc))
            .toList());
  }

  Stream<List<ShoppingList>> archivedListsStream(String householdId) {
    return _firestore
        .collection(AppConstants.shoppingListsCollection)
        .where('householdId', isEqualTo: householdId)
        .where('isArchived', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ShoppingList.fromFirestore(doc))
            .toList());
  }

  Future<ShoppingList> createList({
    required String householdId,
    required String name,
    required String createdBy,
  }) async {
    final data = ShoppingList(
      id: '',
      householdId: householdId,
      name: name,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );

    final ref = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .add(data.toFirestore());

    final doc = await ref.get();
    return ShoppingList.fromFirestore(doc);
  }

  Future<void> updateListName(String listId, String name) async {
    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .update({'name': name});
  }

  Future<void> archiveList(String listId) async {
    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .update({'isArchived': true});
  }

  Future<void> unarchiveList(String listId) async {
    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .update({'isArchived': false});
  }

  Future<void> deleteList(String listId) async {
    // Delete all items first
    final items = await _firestore
        .collection(AppConstants.shoppingItemsCollection)
        .where('listId', isEqualTo: listId)
        .get();

    final batch = _firestore.batch();
    for (final doc in items.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId));
    await batch.commit();
  }

  // ─── Shopping Items ──────────────────────────────────────────────────────────

  Stream<List<ShoppingItem>> itemsStream(String listId) {
    return _firestore
        .collection(AppConstants.shoppingItemsCollection)
        .where('listId', isEqualTo: listId)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ShoppingItem.fromFirestore(doc))
            .toList());
  }

  Future<ShoppingItem> addItem({
    required String listId,
    required String name,
    required String addedBy,
    double quantity = 1,
    String unit = 'stuks',
    String? category,
    String? notes,
    int? order,
  }) async {
    final detectedCategory = category ?? CategoryHelper.detectCategory(name);
    final itemOrder = order ?? DateTime.now().millisecondsSinceEpoch;

    final item = ShoppingItem(
      id: '',
      listId: listId,
      name: name,
      quantity: quantity,
      unit: unit,
      category: detectedCategory,
      notes: notes,
      addedBy: addedBy,
      addedAt: DateTime.now(),
      order: itemOrder,
    );

    final ref = await _firestore
        .collection(AppConstants.shoppingItemsCollection)
        .add(item.toFirestore());

    // Update list item count
    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .update({'itemCount': FieldValue.increment(1)});

    final doc = await ref.get();
    return ShoppingItem.fromFirestore(doc);
  }

  Future<void> updateItem(ShoppingItem item) async {
    await _firestore
        .collection(AppConstants.shoppingItemsCollection)
        .doc(item.id)
        .update(item.toFirestore());
  }

  Future<void> toggleItemChecked({
    required String itemId,
    required String listId,
    required bool isChecked,
    required String userId,
  }) async {
    await _firestore
        .collection(AppConstants.shoppingItemsCollection)
        .doc(itemId)
        .update({
      'isChecked': isChecked,
      'checkedBy': isChecked ? userId : null,
      'checkedAt': isChecked ? Timestamp.now() : null,
    });

    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .update({
      'checkedCount': FieldValue.increment(isChecked ? 1 : -1),
    });
  }

  Future<void> deleteItem(String itemId, String listId) async {
    final doc = await _firestore
        .collection(AppConstants.shoppingItemsCollection)
        .doc(itemId)
        .get();

    if (doc.exists) {
      final item = ShoppingItem.fromFirestore(doc);
      await doc.reference.delete();

      // Update list counts
      await _firestore
          .collection(AppConstants.shoppingListsCollection)
          .doc(listId)
          .update({
        'itemCount': FieldValue.increment(-1),
        if (item.isChecked) 'checkedCount': FieldValue.increment(-1),
      });
    }
  }

  Future<void> clearCheckedItems(String listId) async {
    final items = await _firestore
        .collection(AppConstants.shoppingItemsCollection)
        .where('listId', isEqualTo: listId)
        .where('isChecked', isEqualTo: true)
        .get();

    if (items.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in items.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .update({
      'itemCount': FieldValue.increment(-items.docs.length),
      'checkedCount': 0,
    });
  }

  Future<void> addItemsFromTemplate({
    required String listId,
    required List<Map<String, dynamic>> items,
    required String addedBy,
  }) async {
    final batch = _firestore.batch();
    int baseOrder = DateTime.now().millisecondsSinceEpoch;

    for (final item in items) {
      final ref = _firestore
          .collection(AppConstants.shoppingItemsCollection)
          .doc();

      batch.set(ref, {
        'listId': listId,
        'name': item['name'],
        'quantity': item['quantity'] ?? 1.0,
        'unit': item['unit'] ?? 'stuks',
        'category': item['category'] ?? CategoryHelper.detectCategory(item['name']),
        'notes': null,
        'isChecked': false,
        'checkedBy': null,
        'checkedAt': null,
        'addedBy': addedBy,
        'addedAt': Timestamp.now(),
        'order': baseOrder++,
      });
    }

    await batch.commit();

    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .update({'itemCount': FieldValue.increment(items.length)});
  }
}
