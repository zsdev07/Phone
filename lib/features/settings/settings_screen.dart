import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/call_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDefault = false;
  bool _haptics = true;

  @override
  void initState() {
    super.initState();
    _checkDefaultDialer();
  }

  Future<void> _checkDefaultDialer() async {
    final isDefault = await CallService.isDefaultDialer();
    if (mounted) setState(() => _isDefault = isDefault);
  }

  Future<void> _requestDefault() async {
    await CallService.requestDefaultDialer();
    await Future.delayed(const Duration(seconds: 1));
    await _checkDefaultDialer();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Text(
              'Settings',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SettingsSection(
                  title: 'General',
                  tiles: [
                    _SettingsTile(
                      icon: Icons.phone_outlined,
                      label: 'Default Dialer',
                      subtitle: _isDefault
                          ? 'Phone is your default call app ✓'
                          : 'Tap to set Phone as your default dialer',
                      onTap: _isDefault ? null : _requestDefault,
                      trailing: _isDefault
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppTheme.success, size: 20)
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Set',
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    _SettingsTile(
                      icon: Icons.vibration_rounded,
                      label: 'Haptic Feedback',
                      subtitle: 'Vibrate on key press',
                      onTap: () => setState(() => _haptics = !_haptics),
                      trailing: Switch(
                        value: _haptics,
                        onChanged: (v) => setState(() => _haptics = v),
                        activeColor: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Privacy',
                  tiles: [
                    _SettingsTile(
                      icon: Icons.lock_outlined,
                      label: 'No Data Collection',
                      subtitle: 'Phone never stores or sends your data',
                      onTap: null,
                      trailing: const Icon(Icons.check_circle_rounded,
                          color: AppTheme.success, size: 20),
                    ),
                    _SettingsTile(
                      icon: Icons.wifi_off_rounded,
                      label: 'No Internet Permission',
                      subtitle: 'Zero network access — by design',
                      onTap: null,
                      trailing: const Icon(Icons.check_circle_rounded,
                          color: AppTheme.success, size: 20),
                    ),
                    _SettingsTile(
                      icon: Icons.storage_outlined,
                      label: 'On-Device Only',
                      subtitle:
                          'Uses Android\'s native Contacts & Call Log APIs',
                      onTap: null,
                      trailing: const Icon(Icons.check_circle_rounded,
                          color: AppTheme.success, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'About',
                  tiles: [
                    _SettingsTile(
                      icon: Icons.code_rounded,
                      label: 'Source Code',
                      subtitle: 'View on GitHub — open source, GPL-3.0',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'Version',
                      subtitle: '1.0.0',
                      onTap: null,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.call_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Phone',
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Open source · Privacy first',
                        style: TextStyle(
                          color: AppTheme.onSurfaceMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsTile> tiles;
  const _SettingsSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 0, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: tiles.asMap().entries.map((e) {
              final isLast = e.key == tiles.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    const Divider(indent: 56, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.primaryLight, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.onSurfaceMuted, size: 18)
              : null),
    );
  }
}
