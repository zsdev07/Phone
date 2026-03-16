import 'package:call_log/call_log.dart' as cl;
import 'package:permission_handler/permission_handler.dart';
import '../shared/models/call_log_model.dart';

class CallLogService {
  static Future<bool> requestPermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  static Future<bool> hasPermission() async {
    return await Permission.phone.isGranted;
  }

  static Future<List<PhoneCallLog>> getAll({int limit = 100}) async {
    final granted = await requestPermission();
    if (!granted) return [];

    final raw = await cl.CallLog.get();
    final entries = raw
        .take(limit)
        .map((e) => PhoneCallLog(
              name: e.name,
              number: e.number ?? 'Unknown',
              direction: _mapType(e.callType),
              timestamp: DateTime.fromMillisecondsSinceEpoch(e.timestamp ?? 0),
              duration: Duration(seconds: e.duration ?? 0),
            ))
        .toList();

    return entries;
  }

  static List<PhoneCallLog> filter(
      List<PhoneCallLog> all, CallDirection? direction) {
    if (direction == null) return all;
    return all.where((e) => e.direction == direction).toList();
  }

  static CallDirection _mapType(cl.CallType? type) {
    return switch (type) {
      cl.CallType.incoming => CallDirection.incoming,
      cl.CallType.outgoing => CallDirection.outgoing,
      cl.CallType.missed   => CallDirection.missed,
      cl.CallType.rejected => CallDirection.rejected,
      cl.CallType.blocked  => CallDirection.blocked,
      _                    => CallDirection.unknown,
    };
  }
}
