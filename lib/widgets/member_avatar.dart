import 'package:flutter/material.dart';

class MemberAvatar extends StatelessWidget {
  final String initials;
  final String? avatarUrl;
  final double size;
  final Color? color;

  const MemberAvatar({
    super.key,
    required this.initials,
    this.avatarUrl,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? _colorFromInitials(initials);

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: bgColor,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor,
      child: Text(
        initials.length > 2 ? initials.substring(0, 2) : initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _colorFromInitials(String s) {
    const colors = [
      Color(0xFF1E88E5),
      Color(0xFF43A047),
      Color(0xFFE53935),
      Color(0xFF8E24AA),
      Color(0xFF00ACC1),
      Color(0xFFFF8F00),
      Color(0xFF6D4C41),
      Color(0xFF546E7A),
    ];
    if (s.isEmpty) return colors[0];
    return colors[s.codeUnitAt(0) % colors.length];
  }
}
