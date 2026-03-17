import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id;
  final String listId;
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final String? notes;
  final bool isChecked;
  final String? checkedBy;
  final DateTime? checkedAt;
  final String addedBy;
  final DateTime addedAt;
  final int order;

  ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity = 1,
    this.unit = 'stuks',
    required this.category,
    this.notes,
    this.isChecked = false,
    this.checkedBy,
    this.checkedAt,
    required this.addedBy,
    required this.addedAt,
    required this.order,
  });

  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id,
      listId: data['listId'] ?? '',
      name: data['name'] ?? '',
      quantity: (data['quantity'] ?? 1).toDouble(),
      unit: data['unit'] ?? 'stuks',
      category: data['category'] ?? 'Overig',
      notes: data['notes'],
      isChecked: data['isChecked'] ?? false,
      checkedBy: data['checkedBy'],
      checkedAt: (data['checkedAt'] as Timestamp?)?.toDate(),
      addedBy: data['addedBy'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listId': listId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'notes': notes,
      'isChecked': isChecked,
      'checkedBy': checkedBy,
      'checkedAt': checkedAt != null ? Timestamp.fromDate(checkedAt!) : null,
      'addedBy': addedBy,
      'addedAt': Timestamp.fromDate(addedAt),
      'order': order,
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? listId,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    String? notes,
    bool? isChecked,
    String? checkedBy,
    DateTime? checkedAt,
    String? addedBy,
    DateTime? addedAt,
    int? order,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isChecked: isChecked ?? this.isChecked,
      checkedBy: checkedBy ?? this.checkedBy,
      checkedAt: checkedAt ?? this.checkedAt,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      order: order ?? this.order,
    );
  }
}
