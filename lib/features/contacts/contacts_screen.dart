import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../services/contacts_service.dart';
import '../../services/call_service.dart';
import '../../shared/models/contact_model.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<PhoneContact> _all = [];
  List<PhoneContact> _results = [];
  Map<String, List<PhoneContact>> _grouped = {};
  final _searchController = TextEditingController();
  bool _loading = true;
  bool _permissionDenied = false;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final granted = await ContactsService.requestPermission();
    if (!granted) {
      setState(() {
        _loading = false;
        _permissionDenied = true;
      });
      return;
    }

    final contacts = await ContactsService.getAll();
    if (mounted) {
      setState(() {
        _all = contacts;
        _results = contacts;
        _grouped = ContactsService.groupByLetter(contacts);
        _loading = false;
        _permissionDenied = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchController.text;
    final results = ContactsService.search(_all, q);
    setState(() {
      _results = results;
      _grouped = ContactsService.groupByLetter(results);
    });
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (!_searching) {
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                if (!_searching)
                  const Text(
                    'Contacts',
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                if (_searching)
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                          color: AppTheme.onSurface, fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: 'Search name or number...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: false,
                      ),
                    ),
                  ),
                if (!_searching) const Spacer(),
                IconButton(
                  onPressed: _toggleSearch,
                  icon: Icon(
                      _searching ? Icons.close_rounded : Icons.search_rounded),
                  color: AppTheme.onSurfaceMuted,
                ),
              ],
            ),
          ),

          // Contact count
          if (!_permissionDenied && !_loading && _all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                _searching && _searchController.text.isNotEmpty
                    ? '${_results.length} result${_results.length == 1 ? '' : 's'}'
                    : '${_all.length} contacts',
                style: const TextStyle(
                    color: AppTheme.onSurfaceMuted, fontSize: 13),
              ),
            ),

          // Body
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryLight),
      );
    }

    if (_permissionDenied) {
      return _PermissionPrompt(
        icon: Icons.contacts_rounded,
        title: 'Contacts access needed',
        subtitle:
            'Phone needs permission to show your contacts. Your data stays on-device — no syncing, no servers.',
        onGrant: _load,
      );
    }

    if (_all.isEmpty) {
      return const Center(
        child: Text(
          'No contacts found',
          style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 15),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: AppTheme.onSurfaceMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'No results for "${_searchController.text}"',
              style: const TextStyle(
                  color: AppTheme.onSurfaceMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Grouped alphabetical list
    final letters = _grouped.keys.toList();
    final items = <_ListItem>[];
    for (final letter in letters) {
      items.add(_ListItem.header(letter));
      for (final contact in _grouped[letter]!) {
        items.add(_ListItem.contact(contact));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item.isHeader) {
          return _SectionHeader(letter: item.letter!);
        }
        return _ContactTile(contact: item.contact!)
            .animate(delay: (i * 12).ms)
            .fadeIn(duration: 180.ms)
            .slideX(begin: 0.03, duration: 180.ms);
      },
    );
  }
}

// ── List Item helper ─────────────────────────────────────────────────────────

class _ListItem {
  final bool isHeader;
  final String? letter;
  final PhoneContact? contact;

  const _ListItem.header(this.letter)
      : isHeader = true,
        contact = null;

  const _ListItem.contact(this.contact)
      : isHeader = false,
        letter = null;
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String letter;
  const _SectionHeader({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 0, 6),
      child: Text(
        letter,
        style: const TextStyle(
          color: AppTheme.primaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Contact Tile ──────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final PhoneContact contact;
  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            contact.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      title: Text(
        contact.displayName,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: contact.phones.length > 1
          ? Text(
              '${contact.primaryPhone}  +${contact.phones.length - 1} more',
              style: const TextStyle(
                  color: AppTheme.onSurfaceMuted, fontSize: 12),
            )
          : Text(
              contact.primaryPhone,
              style: const TextStyle(
                  color: AppTheme.onSurfaceMuted, fontSize: 12),
            ),
      trailing: GestureDetector(
        onTap: () => CallService.makeCall(contact.primaryPhone),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.call_outlined,
              color: AppTheme.primaryLight, size: 18),
        ),
      ),
      onTap: () => _showContactSheet(context, contact),
    );
  }

  void _showContactSheet(BuildContext context, PhoneContact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ContactSheet(contact: contact),
    );
  }
}

// ── Contact Bottom Sheet ──────────────────────────────────────────────────────

class _ContactSheet extends StatelessWidget {
  final PhoneContact contact;
  const _ContactSheet({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onSurfaceMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            contact.displayName,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // Phone numbers
          ...contact.phones.map((phone) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.phone_outlined,
                        color: AppTheme.primaryLight, size: 20),
                    title: Text(phone,
                        style: const TextStyle(
                            color: AppTheme.onSurface, fontSize: 15)),
                    trailing: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        CallService.makeCall(phone);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_rounded,
                            color: AppTheme.success, size: 18),
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Permission Prompt ─────────────────────────────────────────────────────────

class _PermissionPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onGrant;

  const _PermissionPrompt({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryLight, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.onSurfaceMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onGrant,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Grant Permission',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
