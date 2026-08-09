String timeLabel(DateTime createdAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final days = today.difference(day).inDays;

  final hour12 = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
  final minute = createdAt.minute.toString().padLeft(2, '0');
  final period = createdAt.hour >= 12 ? 'PM' : 'AM';

  if (days == 0) return 'Today · $hour12:$minute $period';
  if (days == 1) return 'Yesterday';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[createdAt.month - 1]} ${createdAt.day}';
}
