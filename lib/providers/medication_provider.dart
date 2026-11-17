import 'package:flutter/foundation.dart';

import '../core/services/notification_service.dart';
import '../data/models/medication.dart';
import '../data/models/medication_log.dart';
import '../data/repositories/medication_repository.dart';

class MedicationProvider extends ChangeNotifier {
  MedicationProvider({MedicationRepository? repository})
      : _repo = repository ?? MedicationRepository();

  final MedicationRepository _repo;

  List<Medication> _medications = [];
  List<MedicationLog> _logs = [];
  bool _isLoading = false;

  List<Medication> get medications => List.unmodifiable(_medications);
  List<MedicationLog> get logs => List.unmodifiable(_logs);
  bool get isLoading => _isLoading;

  List<Medication> forPet(int petId) =>
      _medications.where((m) => m.petId == petId).toList();

  List<Medication> get activeMedications =>
      _medications.where((m) => m.isCurrentlyActive).toList();

  List<MedicationLog> logsForMedication(int medicationId) =>
      _logs.where((l) => l.medicationId == medicationId).toList();

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _medications = await _repo.getAll();
      _logs = await _repo.getLogs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMedication(
    Medication medication, {
    required String petName,
    required bool notificationsEnabled,
  }) async {
    final id = await _repo.insert(medication);
    final saved = medication.copyWith(id: id);
    await NotificationService.instance.scheduleMedicationReminders(
      medication: saved,
      petName: petName,
      globalEnabled: notificationsEnabled,
    );
    await loadAll();
  }

  Future<void> updateMedication(
    Medication medication, {
    required String petName,
    required bool notificationsEnabled,
  }) async {
    await _repo.update(medication);
    await NotificationService.instance.scheduleMedicationReminders(
      medication: medication,
      petName: petName,
      globalEnabled: notificationsEnabled,
    );
    await loadAll();
  }

  Future<void> deleteMedication(int id) async {
    await _repo.delete(id);
    await NotificationService.instance.cancelMedicationReminders(id);
    await loadAll();
  }

  Future<void> markAdministered({
    required Medication medication,
    String scheduledTime = '',
    String notes = '',
  }) async {
    if (medication.id == null) return;
    await _repo.insertLog(
      MedicationLog(
        medicationId: medication.id!,
        petId: medication.petId,
        administeredAt: DateTime.now(),
        scheduledTime: scheduledTime,
        notes: notes,
      ),
    );
    await loadAll();
  }

  Future<void> deleteLog(int logId) async {
    await _repo.deleteLog(logId);
    await loadAll();
  }
}

