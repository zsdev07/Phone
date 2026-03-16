import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../services/call_service.dart';

class DialpadScreen extends StatefulWidget {
  const DialpadScreen({super.key});

  @override
  State<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends State<DialpadScreen> {
  String _input = '';
  bool _calling = false;

  void _onKeyTap(String value) {
    HapticFeedback.lightImpact();
    setState(() => _input += value);
  }

  void _onDelete() {
    HapticFeedback.mediumImpact();
    if (_input.isNotEmpty) {
      setState(() => _input = _input.substring(0, _input.length - 1));
    }
  }

  void _onDeleteLong() {
    HapticFeedback.heavyImpact();
    setState(() => _input = '');
  }

  Future<void> _onCall() async {
    if (_input.isEmpty || _calling) return;
    HapticFeedback.heavyImpact();

    setState(() => _calling = true);

    try {
      final hasPerm = await CallService.hasCallPermission();

      if (!hasPerm) {
        // No permission yet — use fallback (opens system dialer pre-filled)
        await CallService.openDialerFallback(_input);
        _showSnack('Opening dialer...', AppTheme.primary);
      } else {
        final initiated = await CallService.makeCall(_input);
        if (initiated) {
          _showSnack('Calling $_input', AppTheme.success);
        } else {
          // Permission was just requested — try fallback
          await CallService.openDialerFallback(_input);
        }
      }
    } on CallServiceException catch (e) {
      _showSnack(e.message, AppTheme.error);
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Display
          _DialDisplay(
            input: _input,
            onDelete: _onDelete,
            onDeleteLong: _onDeleteLong,
          ),

          const SizedBox(height: 32),

          // Keypad
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _KeyRow(keys: const [
                    _KeyData('1', ''),
                    _KeyData('2', 'ABC'),
                    _KeyData('3', 'DEF'),
                  ], onTap: _onKeyTap),
                  const SizedBox(height: 12),
                  _KeyRow(keys: const [
                    _KeyData('4', 'GHI'),
                    _KeyData('5', 'JKL'),
                    _KeyData('6', 'MNO'),
                  ], onTap: _onKeyTap),
                  const SizedBox(height: 12),
                  _KeyRow(keys: const [
                    _KeyData('7', 'PQRS'),
                    _KeyData('8', 'TUV'),
                    _KeyData('9', 'WXYZ'),
                  ], onTap: _onKeyTap),
                  const SizedBox(height: 12),
                  _KeyRow(keys: const [
                    _KeyData('*', ''),
                    _KeyData('0', '+'),
                    _KeyData('#', ''),
                  ], onTap: _onKeyTap),
                  const SizedBox(height: 24),

                  // Call button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_input.isNotEmpty) ...[
                        // Add to contacts shortcut
                        _IconAction(
                          icon: Icons.person_add_outlined,
                          onTap: () {}, // Step 4: open create contact
                        ),
                        const SizedBox(width: 24),
                      ],

                      _CallButton(
                        onCall: _onCall,
                        hasInput: _input.isNotEmpty,
                        calling: _calling,
                      ),

                      if (_input.isNotEmpty) ...[
                        const SizedBox(width: 24),
                        // Send SMS shortcut
                        _IconAction(
                          icon: Icons.message_outlined,
                          onTap: () {},
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dial Display ────────────────────────────────────────────────────────────

class _DialDisplay extends StatelessWidget {
  final String input;
  final VoidCallback onDelete;
  final VoidCallback onDeleteLong;

  const _DialDisplay({
    required this.input,
    required this.onDelete,
    required this.onDeleteLong,
  });

  String _format(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (raw.startsWith('+') || raw.length > 10) return raw;
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            child: Text(
              input.isEmpty ? '' : _format(input),
              key: ValueKey(input),
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: input.length > 9 ? 30 : 42,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
          ),
          if (input.isNotEmpty)
            Positioned(
              right: 20,
              child: GestureDetector(
                onTap: onDelete,
                onLongPress: onDeleteLong,
                child: const Icon(
                  Icons.backspace_outlined,
                  color: AppTheme.onSurfaceMuted,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Key Data & Row ──────────────────────────────────────────────────────────

class _KeyData {
  final String main;
  final String sub;
  const _KeyData(this.main, this.sub);
}

class _KeyRow extends StatelessWidget {
  final List<_KeyData> keys;
  final void Function(String) onTap;

  const _KeyRow({required this.keys, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: keys.map((k) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _DialKey(data: k, onTap: onTap),
          ),
        );
      }).toList(),
    );
  }
}

class _DialKey extends StatefulWidget {
  final _KeyData data;
  final void Function(String) onTap;
  const _DialKey({required this.data, required this.onTap});

  @override
  State<_DialKey> createState() => _DialKeyState();
}

class _DialKeyState extends State<_DialKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap(widget.data.main);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: 70,
        decoration: BoxDecoration(
          color: _pressed
              ? AppTheme.primary.withOpacity(0.22)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed
                ? AppTheme.primary.withOpacity(0.45)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.data.main,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontSize: 26,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (widget.data.sub.isNotEmpty)
              Text(
                widget.data.sub,
                style: const TextStyle(
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Call Button ─────────────────────────────────────────────────────────────

class _CallButton extends StatelessWidget {
  final VoidCallback onCall;
  final bool hasInput;
  final bool calling;

  const _CallButton({
    required this.onCall,
    required this.hasInput,
    required this.calling,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCall,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasInput ? AppTheme.success : AppTheme.surfaceVariant,
          boxShadow: hasInput
              ? [
                  BoxShadow(
                    color: AppTheme.success.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: calling
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.call_rounded,
                color: Colors.white,
                size: 30,
              ),
      )
          .animate(target: hasInput ? 1 : 0)
          .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1.0, 1.0),
            duration: 200.ms,
          ),
    );
  }
}

// ── Icon Action (flanking the call button) ──────────────────────────────────

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.onSurfaceMuted, size: 20),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(
          begin: const Offset(0.8, 0.8),
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }
}
