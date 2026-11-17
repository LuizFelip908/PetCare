import 'package:flutter/foundation.dart';

import '../core/services/notification_service.dart';
import '../core/services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;

  bool _notificationsEnabled = true;
  int _appointmentLeadMinutes = 60;
  bool _hasSystemPermission = true;
  bool _isLoaded = false;

  bool get notificationsEnabled => _notificationsEnabled;
  int get appointmentLeadMinutes => _appointmentLeadMinutes;
  bool get hasSystemPermission => _hasSystemPermission;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _notificationsEnabled = await _settingsService.getNotificationsEnabled();
    _appointmentLeadMinutes =
        await _settingsService.getAppointmentLeadMinutes();
    _hasSystemPermission = await NotificationService.instance.hasPermission();
    if (_notificationsEnabled && !_hasSystemPermission) {
      // Android 13+ exige solicitar a permissão em tempo de execução.
      _hasSystemPermission =
          await NotificationService.instance.requestPermissions();
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.instance.requestPermissions();
      _hasSystemPermission = granted;
      if (!granted) {
        _notificationsEnabled = false;
        await _settingsService.setNotificationsEnabled(false);
        notifyListeners();
        return false;
      }
    } else {
      await NotificationService.instance.cancelAll();
    }
    _notificationsEnabled = enabled;
    await _settingsService.setNotificationsEnabled(enabled);
    notifyListeners();
    return true;
  }

  Future<void> setAppointmentLeadMinutes(int minutes) async {
    _appointmentLeadMinutes = minutes;
    await _settingsService.setAppointmentLeadMinutes(minutes);
    notifyListeners();
  }

  Future<bool> refreshSystemPermission() async {
    _hasSystemPermission = await NotificationService.instance.hasPermission();
    notifyListeners();
    return _hasSystemPermission;
  }
}

