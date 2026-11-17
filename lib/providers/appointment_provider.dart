import 'package:flutter/foundation.dart';

import '../core/services/notification_service.dart';
import '../data/models/appointment.dart';
import '../data/repositories/appointment_repository.dart';

class AppointmentProvider extends ChangeNotifier {
  AppointmentProvider({AppointmentRepository? repository})
      : _repo = repository ?? AppointmentRepository();

  final AppointmentRepository _repo;

  List<Appointment> _appointments = [];
  bool _isLoading = false;

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get isLoading => _isLoading;

  List<Appointment> forPet(int petId) =>
      _appointments.where((a) => a.petId == petId).toList();

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now().subtract(const Duration(hours: 1));
    return _appointments
        .where((a) => !a.completed && a.dateTime.isAfter(now))
        .toList();
  }

  List<Appointment> forDay(DateTime day) {
    return _appointments
        .where((a) =>
            a.dateTime.year == day.year &&
            a.dateTime.month == day.month &&
            a.dateTime.day == day.day)
        .toList();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _appointments = await _repo.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAppointment(
    Appointment appointment, {
    required String petName,
    required bool notificationsEnabled,
    int leadMinutes = 60,
  }) async {
    final id = await _repo.insert(appointment);
    final saved = appointment.copyWith(id: id);
    await NotificationService.instance.scheduleAppointmentReminder(
      appointment: saved,
      petName: petName,
      globalEnabled: notificationsEnabled,
      leadMinutes: leadMinutes,
    );
    await loadAll();
  }

  Future<void> updateAppointment(
    Appointment appointment, {
    required String petName,
    required bool notificationsEnabled,
    int leadMinutes = 60,
  }) async {
    await _repo.update(appointment);
    await NotificationService.instance.scheduleAppointmentReminder(
      appointment: appointment,
      petName: petName,
      globalEnabled: notificationsEnabled,
      leadMinutes: leadMinutes,
    );
    await loadAll();
  }

  Future<void> toggleCompleted(
    Appointment appointment, {
    required String petName,
    required bool notificationsEnabled,
    int leadMinutes = 60,
  }) async {
    final updated = appointment.copyWith(completed: !appointment.completed);
    await updateAppointment(
      updated,
      petName: petName,
      notificationsEnabled: notificationsEnabled,
      leadMinutes: leadMinutes,
    );
  }

  Future<void> deleteAppointment(int id) async {
    await _repo.delete(id);
    await NotificationService.instance.cancelAppointmentReminder(id);
    await loadAll();
  }
}

