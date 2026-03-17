import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingList {
  final String id;
  final String householdId;
  final String name;
  final DateTime createdAt;
  final String createdBy;
  final bool isArchived;
  final int itemCount;
  final int checkedCount;

  ShoppingList({
    required this.id,
    required this.householdId,
    required this.name,
    required this.createdAt,
    required this.createdBy,
    this.isArchived = false,
    this.itemCount = 0,
    this.checkedCount = 0,
  });

  factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingList(
      id: doc.id,
      householdId: data['householdId'] ?? '',
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      isArchived: data['isArchived'] ?? false,
      itemCount: data['itemCount'] ?? 0,
      checkedCount: data['checkedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isArchived': isArchived,
      'itemCount': itemCount,
      'checkedCount': checkedCount,
    };
  }

  ShoppingList copyWith({
    String? id,
    String? householdId,
    String? name,
    DateTime? createdAt,
    String? createdBy,
    bool? isArchived,
    int? itemCount,
    int? checkedCount,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isArchived: isArchived ?? this.isArchived,
      itemCount: itemCount ?? this.itemCount,
      checkedCount: checkedCount ?? this.checkedCount,
    );
  }

  double get completionPercentage {
    if (itemCount == 0) return 0;
    return checkedCount / itemCount;
  }
}
