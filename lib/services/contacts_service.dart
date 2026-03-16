import 'package:flutter_contacts/flutter_contacts.dart';
import '../shared/models/contact_model.dart';

class ContactsService {
  /// Request READ_CONTACTS permission.
  /// Returns true if granted.
  static Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission(readonly: true);
  }

  /// Check if READ_CONTACTS permission is already granted.
  static Future<bool> hasPermission() async {
    return await FlutterContacts.requestPermission(readonly: true);
  }

  /// Load all contacts, sorted alphabetically by display name.
  static Future<List<PhoneContact>> getAll() async {
    final granted = await requestPermission();
    if (!granted) return [];

    final raw = await FlutterContacts.getContacts(
      withProperties: true,
      withThumbnail: false, // keep it fast; load thumbnails lazily if needed
    );

    final contacts = raw
        .where((c) => c.phones.isNotEmpty)
        .map((c) => PhoneContact(
              id: c.id,
              displayName: c.displayName,
              phones: c.phones.map((p) => p.number).toList(),
              thumbnailPath: null,
            ))
        .toList();

    contacts.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    return contacts;
  }

  /// Search contacts by name or number.
  static List<PhoneContact> search(
      List<PhoneContact> all, String query) {
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((c) {
      return c.displayName.toLowerCase().contains(q) ||
          c.phones.any((p) => p.contains(q));
    }).toList();
  }

  /// Group contacts by first letter of display name.
  static Map<String, List<PhoneContact>> groupByLetter(
      List<PhoneContact> contacts) {
    final map = <String, List<PhoneContact>>{};
    for (final contact in contacts) {
      final letter = contact.displayName.isNotEmpty
          ? contact.displayName[0].toUpperCase()
          : '#';
      final key = RegExp(r'[A-Z]').hasMatch(letter) ? letter : '#';
      map.putIfAbsent(key, () => []).add(contact);
    }
    // Sort keys: A-Z then #
    final sorted = Map.fromEntries(
      (map.entries.toList()
            ..sort((a, b) {
              if (a.key == '#') return 1;
              if (b.key == '#') return -1;
              return a.key.compareTo(b.key);
            }))
          .map((e) => MapEntry(e.key, e.value)),
    );
    return sorted;
  }
}
