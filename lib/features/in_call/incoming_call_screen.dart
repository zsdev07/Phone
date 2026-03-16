import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../services/call_service.dart';

/// Entry point for the IncomingCallActivity Flutter view
@pragma('vm:entry-point')
void incomingCallMain() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const IncomingCallApp());
}

class IncomingCallApp extends StatelessWidget {
  const IncomingCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          brightness: Brightness.dark,
        ).copyWith(surface: AppTheme.surface),
        scaffoldBackgroundColor: AppTheme.surface,
      ),
      home: const IncomingCallScreen(),
    );
  }
}

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  static const _incomingChannel = MethodChannel('zx.offical.phone/incoming');

  String _callerNumber = '';
  String _callerName   = '';
  bool _loading = true;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadCallerInfo();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCallerInfo() async {
    try {
      final info = await _incomingChannel.invokeMapMethod<String, dynamic>(
          'getCallerInfo');
      if (mounted && info != null) {
        setState(() {
          _callerNumber = info['number'] as String? ?? 'Unknown';
          _callerName   = info['name']   as String? ?? '';
          _loading      = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _answer() async {
    HapticFeedback.heavyImpact();
    await _incomingChannel.invokeMethod('answer');
  }

  Future<void> _decline() async {
    HapticFeedback.heavyImpact();
    await _incomingChannel.invokeMethod('decline');
  }

  String get _displayName =>
      _callerName.isNotEmpty ? _callerName : _callerNumber;

  String get _initials {
    final parts = _displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '#';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Animated purple radial glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final scale = 1.0 + (_pulseController.value * 0.15);
              return Positioned(
                top: -150,
                left: MediaQuery.of(context).size.width / 2 - 200,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryLight),
                  )
                : Column(
                    children: [
                      const SizedBox(height: 48),

                      // Incoming label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Incoming call',
                          style: TextStyle(
                            color: AppTheme.onSurfaceMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 48),

                      // Pulsing avatar
                      _PulsingAvatar(
                        initials: _initials,
                        controller: _pulseController,
                      ).animate().fadeIn(duration: 600.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 24),

                      // Caller name
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                      if (_callerName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _callerNumber,
                            style: const TextStyle(
                              color: AppTheme.onSurfaceMuted,
                              fontSize: 16,
                            ),
                          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                        ),

                      const Spacer(),

                      // Answer / Decline buttons
                      _AnswerDeclineRow(
                        onAnswer: _answer,
                        onDecline: _decline,
                      ).animate().fadeIn(delay: 250.ms, duration: 500.ms)
                          .slideY(begin: 0.15, duration: 500.ms,
                                  curve: Curves.easeOut),

                      const SizedBox(height: 56),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing Avatar ────────────────────────────────────────────────────────────

class _PulsingAvatar extends StatelessWidget {
  final String initials;
  final AnimationController controller;

  const _PulsingAvatar({required this.initials, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final ringOpacity = (1.0 - controller.value) * 0.35;
        final ringScale   = 1.0 + controller.value * 0.5;
        return SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Transform.scale(
                scale: ringScale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(ringOpacity),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Avatar
              Container(
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
                      color: AppTheme.primary.withOpacity(0.45),
                      blurRadius: 28,
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
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Answer / Decline Row ──────────────────────────────────────────────────────

class _AnswerDeclineRow extends StatelessWidget {
  final VoidCallback onAnswer;
  final VoidCallback onDecline;

  const _AnswerDeclineRow({required this.onAnswer, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Decline
        Column(
          children: [
            GestureDetector(
              onTap: onDecline,
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
                    Icons.call_end_rounded, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Decline',
                style: TextStyle(
                    color: AppTheme.onSurfaceMuted, fontSize: 13)),
          ],
        ),

        // Answer
        Column(
          children: [
            GestureDetector(
              onTap: onAnswer,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.success,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                    Icons.call_rounded, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Answer',
                style: TextStyle(
                    color: AppTheme.onSurfaceMuted, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
