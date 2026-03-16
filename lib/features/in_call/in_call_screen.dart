import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../services/call_service.dart';

class InCallScreen extends StatefulWidget {
  final String callerNumber;
  final String? callerName;

  const InCallScreen({
    super.key,
    required this.callerNumber,
    this.callerName,
  });

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  // Controls
  bool _muted    = false;
  bool _speaker  = false;
  bool _held     = false;
  bool _keypad   = false;
  String _keypadInput = '';

  // Timer
  int _seconds = 0;
  Timer? _timer;

  // Call state
  late StreamSubscription<CallStateEvent> _stateSub;
  String _status = 'Calling...';

  @override
  void initState() {
    super.initState();
    _startTimer();
    _stateSub = CallService.callStateStream.listen(_onCallState);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stateSub.cancel();
    super.dispose();
  }

  void _onCallState(CallStateEvent event) {
    if (!mounted) return;
    if (event.isDisconnected) {
      Navigator.of(context).pop();
    } else if (event.isActive) {
      setState(() => _status = _formatDuration(_seconds));
    } else if (event.isHolding) {
      setState(() => _status = 'On hold');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _seconds++;
        if (_status != 'On hold') _status = _formatDuration(_seconds);
      });
    });
  }

  String _formatDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    HapticFeedback.lightImpact();
    setState(() => _muted = !_muted);
    // TODO: wire to AudioManager via platform channel in Step 6
  }

  Future<void> _toggleSpeaker() async {
    HapticFeedback.lightImpact();
    setState(() => _speaker = !_speaker);
    // TODO: wire to AudioManager
  }

  Future<void> _toggleHold() async {
    HapticFeedback.lightImpact();
    if (_held) {
      await CallService.unholdCall();
    } else {
      await CallService.holdCall();
    }
    setState(() => _held = !_held);
  }

  Future<void> _endCall() async {
    HapticFeedback.heavyImpact();
    await CallService.endCall();
  }

  String get _displayName =>
      (widget.callerName != null && widget.callerName!.isNotEmpty)
          ? widget.callerName!
          : widget.callerNumber;

  String get _initials {
    final name = _displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '#';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Purple ambient glow
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Status pill
                _StatusPill(status: _status, held: _held)
                    .animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 40),

                // Avatar
                _CallerAvatar(initials: _initials)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.8, 0.8), duration: 500.ms,
                           curve: Curves.easeOutBack),

                const SizedBox(height: 20),

                // Name
                Text(
                  _displayName,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                if (widget.callerName != null && widget.callerName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.callerNumber,
                      style: const TextStyle(
                          color: AppTheme.onSurfaceMuted, fontSize: 15),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                  ),

                const Spacer(),

                // Keypad overlay
                if (_keypad) _KeypadOverlay(
                  input: _keypadInput,
                  onKey: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _keypadInput += v);
                  },
                  onClose: () => setState(() => _keypad = false),
                ).animate().fadeIn(duration: 200.ms).slideY(
                      begin: 0.1, duration: 200.ms, curve: Curves.easeOut),

                // Controls grid
                if (!_keypad) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _ControlsGrid(
                      muted:   _muted,
                      speaker: _speaker,
                      held:    _held,
                      onMute:    _toggleMute,
                      onSpeaker: _toggleSpeaker,
                      onHold:    _toggleHold,
                      onKeypad: () => setState(() => _keypad = true),
                      onContacts: () {},
                      onAdd: () {},
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ],

                const SizedBox(height: 32),

                // End call button
                _EndCallButton(onEnd: _endCall)
                    .animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  final bool held;
  const _StatusPill({required this.status, required this.held});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: held
            ? AppTheme.primaryDark.withOpacity(0.4)
            : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!held)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 7),
              decoration: const BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            status,
            style: TextStyle(
              color: held ? AppTheme.primaryLight : AppTheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Caller Avatar ─────────────────────────────────────────────────────────────

class _CallerAvatar extends StatelessWidget {
  final String initials;
  const _CallerAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Controls Grid ─────────────────────────────────────────────────────────────

class _ControlsGrid extends StatelessWidget {
  final bool muted, speaker, held;
  final VoidCallback onMute, onSpeaker, onHold, onKeypad, onContacts, onAdd;

  const _ControlsGrid({
    required this.muted,
    required this.speaker,
    required this.held,
    required this.onMute,
    required this.onSpeaker,
    required this.onHold,
    required this.onKeypad,
    required this.onContacts,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _ControlButton(
          icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: 'Mute',
          active: muted,
          onTap: onMute,
        ),
        _ControlButton(
          icon: speaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
          label: 'Speaker',
          active: speaker,
          onTap: onSpeaker,
        ),
        _ControlButton(
          icon: Icons.dialpad_rounded,
          label: 'Keypad',
          active: false,
          onTap: onKeypad,
        ),
        _ControlButton(
          icon: held ? Icons.play_arrow_rounded : Icons.pause_rounded,
          label: held ? 'Unhold' : 'Hold',
          active: held,
          onTap: onHold,
        ),
        _ControlButton(
          icon: Icons.person_add_outlined,
          label: 'Contacts',
          active: false,
          onTap: onContacts,
        ),
        _ControlButton(
          icon: Icons.group_add_outlined,
          label: 'Add call',
          active: false,
          onTap: onAdd,
        ),
      ],
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: widget.active
              ? AppTheme.primary.withOpacity(0.2)
              : _pressed
                  ? AppTheme.surfaceVariant.withOpacity(0.7)
                  : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.active
                ? AppTheme.primary.withOpacity(0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              color: widget.active ? AppTheme.primaryLight : AppTheme.onSurface,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.active
                    ? AppTheme.primaryLight
                    : AppTheme.onSurfaceMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── End Call Button ───────────────────────────────────────────────────────────

class _EndCallButton extends StatelessWidget {
  final VoidCallback onEnd;
  const _EndCallButton({required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEnd,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.error,
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.call_end_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

// ── Keypad Overlay ────────────────────────────────────────────────────────────

class _KeypadOverlay extends StatelessWidget {
  final String input;
  final void Function(String) onKey;
  final VoidCallback onClose;

  const _KeypadOverlay({
    required this.input,
    required this.onKey,
    required this.onClose,
  });

  static const _keys = [
    ['1','2','3'],
    ['4','5','6'],
    ['7','8','9'],
    ['*','0','#'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Input display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                input,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.keyboard_hide_rounded,
                    color: AppTheme.onSurfaceMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Keys
          for (final row in _keys) ...[
            Row(
              children: row.map((k) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: GestureDetector(
                      onTap: () => onKey(k),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(k,
                              style: const TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                              )),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
