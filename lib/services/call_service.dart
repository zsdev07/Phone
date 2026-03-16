import 'package:flutter/services.dart';

class CallService {
  static const _channel      = MethodChannel('zx.offical.phone/call');
  static const _stateChannel = EventChannel('zx.offical.phone/call_state');

  // ── Call state stream ────────────────────────────────────────────────────
  /// Emits maps with keys: 'state' (String), 'number' (String)
  /// States: dialing | ringing | active | holding | disconnected | restore_incall
  static Stream<CallStateEvent> get callStateStream =>
      _stateChannel.receiveBroadcastStream().map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        return CallStateEvent(
          state:  map['state']  as String,
          number: map['number'] as String? ?? '',
        );
      });

  // ── Actions ──────────────────────────────────────────────────────────────
  static Future<bool> makeCall(String number) async {
    try {
      return await _channel.invokeMethod<bool>('makeCall', {'number': number}) ?? false;
    } on PlatformException catch (e) {
      throw CallServiceException(e.message ?? 'Call failed');
    }
  }

  static Future<bool> hasCallPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasCallPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> requestCallPermission() async {
    await _channel.invokeMethod('requestCallPermission');
  }

  static Future<bool> isDefaultDialer() async {
    try {
      return await _channel.invokeMethod<bool>('isDefaultDialer') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> requestDefaultDialer() async {
    await _channel.invokeMethod('requestDefaultDialer');
  }

  static Future<void> openDialerFallback(String number) async {
    await _channel.invokeMethod('openDialerFallback', {'number': number});
  }

  static Future<void> endCall() async {
    await _channel.invokeMethod('endCall');
  }

  static Future<void> answerCall() async {
    await _channel.invokeMethod('answerCall');
  }

  static Future<void> holdCall() async {
    await _channel.invokeMethod('holdCall');
  }

  static Future<void> unholdCall() async {
    await _channel.invokeMethod('unholdCall');
  }
}

class CallStateEvent {
  final String state;
  final String number;
  const CallStateEvent({required this.state, required this.number});

  bool get isRinging      => state == 'ringing';
  bool get isActive       => state == 'active';
  bool get isDisconnected => state == 'disconnected';
  bool get isDialing      => state == 'dialing';
  bool get isHolding      => state == 'holding';
}

class CallServiceException implements Exception {
  final String message;
  const CallServiceException(this.message);
  @override
  String toString() => 'CallServiceException: $message';
}
