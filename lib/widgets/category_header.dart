import 'package:flutter/material.dart';
import '../config/theme.dart';

class CategoryHeader extends StatelessWidget {
  final String category;
  final int itemCount;
  final int checkedCount;

  const CategoryHeader({
    super.key,
    required this.category,
    required this.itemCount,
    required this.checkedCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getCategoryColor(category);
    final icon = AppTheme.getCategoryIcon(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.backgroundColor,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            category,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            '$checkedCount/$itemCount',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
