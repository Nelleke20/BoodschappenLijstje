import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/shopping_item.dart';
import '../config/theme.dart';

class ListItemTile extends StatelessWidget {
  final ShoppingItem item;
  final String addedByInitials;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ListItemTile({
    super.key,
    required this.item,
    required this.addedByInitials,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppTheme.getCategoryColor(item.category);

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.4,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
            icon: Icons.edit_outlined,
            label: 'Wijzig',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: 'Verwijder',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onToggle();
        },
        onLongPress: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100),
            ),
          ),
          child: Row(
            children: [
              // Category color indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: item.isChecked
                      ? Colors.grey.shade200
                      : categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isChecked
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  color: item.isChecked
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                ),
                child: item.isChecked
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Item info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: item.isChecked
                            ? Colors.grey.shade400
                            : AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _quantityText(),
                          style: TextStyle(
                            fontSize: 13,
                            color: item.isChecked
                                ? Colors.grey.shade300
                                : Colors.grey.shade500,
                          ),
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          Text(
                            ' · ',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          Expanded(
                            child: Text(
                              item.notes!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Added by avatar
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _avatarColor(addedByInitials),
                ),
                child: Center(
                  child: Text(
                    addedByInitials.isEmpty
                        ? '?'
                        : addedByInitials[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _quantityText() {
    if (item.quantity == 1 && item.unit == 'stuks') {
      return item.category;
    }
    final qty = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    return '$qty ${item.unit} · ${item.category}';
  }

  Color _avatarColor(String s) {
    const colors = [
      Color(0xFF1E88E5),
      Color(0xFF43A047),
      Color(0xFFE53935),
      Color(0xFF8E24AA),
      Color(0xFF00ACC1),
    ];
    if (s.isEmpty) return colors[0];
    return colors[s.codeUnitAt(0) % colors.length];
  }
}
