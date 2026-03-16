enum CallDirection { incoming, outgoing, missed, rejected, blocked, unknown }

class CallLogEntry {
  final String? name;
  final String number;
  final CallDirection direction;
  final DateTime timestamp;
  final Duration duration;

  const CallLogEntry({
    this.name,
    required this.number,
    required this.direction,
    required this.timestamp,
    required this.duration,
  });

  String get displayName => (name != null && name!.isNotEmpty) ? name! : number;

  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.trim().split(' ');
      if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      return name![0].toUpperCase();
    }
    return '#';
  }

  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    }
    return '${timestamp.day}/${timestamp.month}';
  }

  String get durationString {
    if (duration.inSeconds == 0) return '';
    if (duration.inMinutes == 0) return '${duration.inSeconds}s';
    return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
  }
}
