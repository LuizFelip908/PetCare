import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/appointment.dart';
import '../../data/models/medication.dart';
import '../../data/models/vaccine.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'petcare_reminders';
  static const String _channelName = 'Lembretes PetCare';
  static const String _channelDesc =
      'Lembretes de medicamentos, vacinas e consultas do seu pet';

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      try {
        final localTimezone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      } catch (_) {
        // Fallback to America/Sao_Paulo or UTC if device timezone lookup fails
        try {
          tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
        } catch (_) {}
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService initialize skipped: $e');
    }
  }

  Future<bool> requestPermissions() async {
    await initialize();
    if (!_initialized) return false;
    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? true;
      } else if (Platform.isIOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
  }

  Future<bool> hasPermission() async {
    await initialize();
    if (!_initialized) return false;
    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await androidImpl?.areNotificationsEnabled();
        return enabled ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails get _defaultDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  int _appointmentNotifId(int appointmentId) => 100000 + appointmentId;
  int _vaccineNotifId(int vaccineId) => 200000 + vaccineId;
  int _medicationNotifId(int medicationId, int index) =>
      300000 + (medicationId * 10) + index;

  Future<void> scheduleAppointmentReminder({
    required Appointment appointment,
    required String petName,
    required bool globalEnabled,
    int leadMinutes = 60,
  }) async {
    if (appointment.id == null) return;
    await cancelAppointmentReminder(appointment.id!);

    if (!globalEnabled ||
        !appointment.reminderEnabled ||
        appointment.completed) {
      return;
    }

    await initialize();
    if (!_initialized) return;

    final scheduled = appointment.dateTime.subtract(
      Duration(minutes: leadMinutes),
    );
    if (scheduled.isBefore(DateTime.now())) return;

    final tzDate = tz.TZDateTime.from(scheduled, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: _appointmentNotifId(appointment.id!),
        title: '${appointment.type.label} • $petName',
        body: '${appointment.title}'
            '${appointment.location.isNotEmpty ? ' em ${appointment.location}' : ''}',
        scheduledDate: tzDate,
        notificationDetails: _defaultDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule appointment reminder: $e');
    }
  }

  Future<void> cancelAppointmentReminder(int appointmentId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _appointmentNotifId(appointmentId));
    } catch (_) {}
  }

  Future<void> scheduleVaccineReminder({
    required Vaccine vaccine,
    required String petName,
    required bool globalEnabled,
  }) async {
    if (vaccine.id == null) return;
    await cancelVaccineReminder(vaccine.id!);

    if (!globalEnabled ||
        !vaccine.reminderEnabled ||
        vaccine.nextDoseAt == null) {
      return;
    }

    await initialize();
    if (!_initialized) return;

    // Remind at 09:00 on the next dose day
    final next = vaccine.nextDoseAt!;
    final scheduled = DateTime(next.year, next.month, next.day, 9, 0);
    if (scheduled.isBefore(DateTime.now())) return;

    final tzDate = tz.TZDateTime.from(scheduled, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: _vaccineNotifId(vaccine.id!),
        title: 'Vacina prevista • $petName',
        body: 'Próxima dose de ${vaccine.name} prevista para hoje.',
        scheduledDate: tzDate,
        notificationDetails: _defaultDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule vaccine reminder: $e');
    }
  }

  Future<void> cancelVaccineReminder(int vaccineId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _vaccineNotifId(vaccineId));
    } catch (_) {}
  }

  Future<void> scheduleMedicationReminders({
    required Medication medication,
    required String petName,
    required bool globalEnabled,
  }) async {
    if (medication.id == null) return;
    await cancelMedicationReminders(medication.id!);

    if (!globalEnabled ||
        !medication.reminderEnabled ||
        !medication.isCurrentlyActive) {
      return;
    }

    await initialize();
    if (!_initialized) return;

    final now = DateTime.now();
    for (int i = 0; i < medication.schedules.length && i < 10; i++) {
      final parts = medication.schedules[i].split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      DateTime nextOccurrence = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (nextOccurrence.isBefore(now)) {
        nextOccurrence = nextOccurrence.add(const Duration(days: 1));
      }
      if (medication.endDate != null) {
        final endOfTreatment = DateTime(
          medication.endDate!.year,
          medication.endDate!.month,
          medication.endDate!.day,
          23,
          59,
        );
        if (nextOccurrence.isAfter(endOfTreatment)) continue;
      }

      final tzDate = tz.TZDateTime.from(nextOccurrence, tz.local);
      try {
        await _plugin.zonedSchedule(
          id: _medicationNotifId(medication.id!, i),
          title: 'Hora do medicamento • $petName',
          body: '${medication.name}'
              '${medication.dosage.isNotEmpty ? ' (${medication.dosage})' : ''}'
              ' — ${medication.schedules[i]}',
          scheduledDate: tzDate,
          notificationDetails: _defaultDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('Failed to schedule medication reminder: $e');
      }
    }
  }

  Future<void> cancelMedicationReminders(int medicationId) async {
    if (!_initialized) return;
    for (int i = 0; i < 10; i++) {
      try {
        await _plugin.cancel(id: _medicationNotifId(medicationId, i));
      } catch (_) {}
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

