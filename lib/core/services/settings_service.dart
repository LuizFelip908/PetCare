import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _appointmentLeadMinutesKey = 'appointment_lead_minutes';

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<int> getAppointmentLeadMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_appointmentLeadMinutesKey) ?? 60;
  }

  Future<void> setAppointmentLeadMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_appointmentLeadMinutesKey, minutes);
  }
}

