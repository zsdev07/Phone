import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import '../shared/models/call_log_model.dart';

class CallLogService {
  /// Request READ_CALL_LOG permission.
  static Future<bool> requestPermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// Check if READ_CALL_LOG permission is granted.
  static Future<bool> hasPermission() async {
    return await Permission.phone.isGranted;
  }

  /// Load call log entries, most recent first.
  /// [limit] — how many entries to fetch (default 100).
  static Future<List<CallLogEntry>> getAll({int limit = 100}) async {
    final granted = await requestPermission();
    if (!granted) return [];

    final raw = await CallLog.get();
    final entries = raw
        .take(limit)
        .map((e) => CallLogEntry(
              name: e.name,
              number: e.number ?? 'Unknown',
              direction: _mapType(e.callType),
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                  e.timestamp ?? 0),
              duration: Duration(seconds: e.duration ?? 0),
            ))
        .toList();

    return entries;
  }

  /// Filter entries by direction type.
  static List<CallLogEntry> filter(
      List<CallLogEntry> all, CallDirection? direction) {
    if (direction == null) return all;
    return all.where((e) => e.direction == direction).toList();
  }

  static CallDirection _mapType(CallType? type) {
    return switch (type) {
      CallType.incoming => CallDirection.incoming,
      CallType.outgoing => CallDirection.outgoing,
      CallType.missed   => CallDirection.missed,
      CallType.rejected => CallDirection.rejected,
      CallType.blocked  => CallDirection.blocked,
      _                 => CallDirection.unknown,
    };
  }
}
