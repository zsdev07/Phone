import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request CALL_PHONE permission. Returns true if granted.
  static Future<bool> requestCallPhone() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// Check if CALL_PHONE is already granted.
  static Future<bool> hasCallPhone() async {
    return await Permission.phone.isGranted;
  }

  /// Request READ_CONTACTS permission. Returns true if granted.
  static Future<bool> requestContacts() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// Request READ_CALL_LOG permission. Returns true if granted.
  static Future<bool> requestCallLog() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// Request all permissions needed at startup.
  static Future<Map<Permission, PermissionStatus>> requestAll() async {
    return await [
      Permission.phone,
      Permission.contacts,
    ].request();
  }

  /// Open app settings if permanently denied.
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
