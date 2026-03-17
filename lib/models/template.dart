import 'package:cloud_firestore/cloud_firestore.dart';

class TemplateItem {
  final String name;
  final String category;
  final double quantity;
  final String unit;

  TemplateItem({
    required this.name,
    required this.category,
    this.quantity = 1,
    this.unit = 'stuks',
  });

  factory TemplateItem.fromMap(Map<String, dynamic> data) {
    return TemplateItem(
      name: data['name'] ?? '',
      category: data['category'] ?? 'Overig',
      quantity: (data['quantity'] ?? 1).toDouble(),
      unit: data['unit'] ?? 'stuks',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class ShoppingTemplate {
  final String id;
  final String? householdId;
  final String name;
  final List<TemplateItem> items;
  final bool isDefault;
  final String? createdBy;
  final DateTime? createdAt;

  ShoppingTemplate({
    required this.id,
    this.householdId,
    required this.name,
    required this.items,
    this.isDefault = false,
    this.createdBy,
    this.createdAt,
  });

  factory ShoppingTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((item) => TemplateItem.fromMap(item as Map<String, dynamic>))
        .toList();
    return ShoppingTemplate(
      id: doc.id,
      householdId: data['householdId'],
      name: data['name'] ?? '',
      items: itemsList,
      isDefault: data['isDefault'] ?? false,
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId,
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
      'isDefault': isDefault,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
