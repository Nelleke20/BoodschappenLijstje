extension DateTimeExtensions on DateTime {
  String toNlDateString() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);

    if (date == today) return 'Vandaag';
    if (date == today.subtract(const Duration(days: 1))) return 'Gisteren';
    if (date == today.add(const Duration(days: 1))) return 'Morgen';

    final months = [
      '', 'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
    ];

    return '$day ${months[month]}';
  }

  String toNlFullDateString() {
    final days = [
      '', 'maandag', 'dinsdag', 'woensdag', 'donderdag',
      'vrijdag', 'zaterdag', 'zondag'
    ];
    final months = [
      '', 'januari', 'februari', 'maart', 'april', 'mei', 'juni',
      'juli', 'augustus', 'september', 'oktober', 'november', 'december'
    ];
    return '${days[weekday]} $day ${months[month]} $year';
  }
}

extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
