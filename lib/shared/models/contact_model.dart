class PhoneContact {
  final String id;
  final String displayName;
  final List<String> phones;
  final String? thumbnailPath;

  const PhoneContact({
    required this.id,
    required this.displayName,
    required this.phones,
    this.thumbnailPath,
  });

  String get primaryPhone => phones.isNotEmpty ? phones.first : '';

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}
