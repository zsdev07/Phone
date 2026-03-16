import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../services/call_log_service.dart';
import '../../services/call_service.dart';
import '../../shared/models/call_log_model.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  List<PhoneCallLog> _all = [];
  List<PhoneCallLog> _filtered = [];
  CallDirection? _activeFilter;
  bool _loading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final granted = await CallLogService.requestPermission();
    if (!granted) {
      setState(() {
        _loading = false;
        _permissionDenied = true;
      });
      return;
    }

    final entries = await CallLogService.getAll();
    if (mounted) {
      setState(() {
        _all = entries;
        _filtered = CallLogService.filter(entries, _activeFilter);
        _loading = false;
        _permissionDenied = false;
      });
    }
  }

  void _setFilter(CallDirection? direction) {
    setState(() {
      _activeFilter = direction;
      _filtered = CallLogService.filter(_all, direction);
    });
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
                const Text(
                  'Recents',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                if (!_loading && !_permissionDenied)
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppTheme.onSurfaceMuted,
                    iconSize: 20,
                  ),
              ],
            ),
          ),

          // Filter chips
          if (!_permissionDenied) ...[
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _activeFilter == null,
                    onTap: () => _setFilter(null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Missed',
                    selected: _activeFilter == CallDirection.missed,
                    onTap: () => _setFilter(CallDirection.missed),
                    color: AppTheme.error,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Incoming',
                    selected: _activeFilter == CallDirection.incoming,
                    onTap: () => _setFilter(CallDirection.incoming),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Outgoing',
                    selected: _activeFilter == CallDirection.outgoing,
                    onTap: () => _setFilter(CallDirection.outgoing),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

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
        icon: Icons.history_rounded,
        title: 'Call log access needed',
        subtitle:
            'Phone needs permission to show your recent calls. No data leaves your device.',
        onGrant: _load,
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 52, color: AppTheme.onSurfaceMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              _activeFilter == null ? 'No recent calls' : 'No calls here',
              style: const TextStyle(
                  color: AppTheme.onSurfaceMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filtered.length,
      itemBuilder: (context, i) {
        return _CallLogTile(entry: _filtered[i])
            .animate(delay: (i * 20).ms)
            .fadeIn(duration: 200.ms)
            .slideX(begin: 0.03, duration: 200.ms);
      },
    );
  }
}

// ── Call Log Tile ────────────────────────────────────────────────────────────

class _CallLogTile extends StatelessWidget {
  final PhoneCallLog entry;
  const _CallLogTile({required this.entry});

  IconData get _dirIcon {
    return switch (entry.direction) {
      CallDirection.incoming => Icons.call_received_rounded,
      CallDirection.outgoing => Icons.call_made_rounded,
      CallDirection.missed   => Icons.call_missed_rounded,
      CallDirection.rejected => Icons.call_missed_rounded,
      _                      => Icons.call_rounded,
    };
  }

  Color get _dirColor {
    return switch (entry.direction) {
      CallDirection.incoming => AppTheme.primaryLight,
      CallDirection.outgoing => AppTheme.onSurfaceMuted,
      CallDirection.missed   => AppTheme.error,
      CallDirection.rejected => AppTheme.error,
      _                      => AppTheme.onSurfaceMuted,
    };
  }

  bool get _isMissed =>
      entry.direction == CallDirection.missed ||
      entry.direction == CallDirection.rejected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            entry.initials,
            style: TextStyle(
              color: _isMissed ? AppTheme.error : AppTheme.primaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      title: Text(
        entry.displayName,
        style: TextStyle(
          color: _isMissed ? AppTheme.error : AppTheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(_dirIcon, size: 13, color: _dirColor),
          const SizedBox(width: 4),
          Text(
            entry.number == entry.displayName ? '' : entry.number,
            style: const TextStyle(
                color: AppTheme.onSurfaceMuted, fontSize: 12),
          ),
          if (entry.durationString.isNotEmpty) ...[
            const Text(' · ',
                style: TextStyle(
                    color: AppTheme.onSurfaceMuted, fontSize: 12)),
            Text(
              entry.durationString,
              style: const TextStyle(
                  color: AppTheme.onSurfaceMuted, fontSize: 12),
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            entry.relativeTime,
            style: const TextStyle(
                color: AppTheme.onSurfaceMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => CallService.makeCall(entry.number),
            child: const Icon(Icons.call_outlined,
                size: 16, color: AppTheme.primaryLight),
          ),
        ],
      ),
      onTap: () => CallService.makeCall(entry.number),
    );
  }
}

// ── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.2)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? (color ?? AppTheme.primaryLight) : AppTheme.onSurfaceMuted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Permission Prompt (shared) ───────────────────────────────────────────────

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
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.onSurfaceMuted,
                fontSize: 13,
                height: 1.5,
              ),
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
              child: const Text(
                'Grant Permission',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
