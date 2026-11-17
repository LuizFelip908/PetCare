import 'package:flutter/foundation.dart';

import '../core/services/notification_service.dart';
import '../data/models/vaccine.dart';
import '../data/repositories/vaccine_repository.dart';

class VaccineProvider extends ChangeNotifier {
  VaccineProvider({VaccineRepository? repository})
      : _repo = repository ?? VaccineRepository();

  final VaccineRepository _repo;

  List<Vaccine> _vaccines = [];
  bool _isLoading = false;

  List<Vaccine> get vaccines => List.unmodifiable(_vaccines);
  bool get isLoading => _isLoading;

  List<Vaccine> forPet(int petId) =>
      _vaccines.where((v) => v.petId == petId).toList();

  List<Vaccine> get upcomingDoses {
    final now = DateTime.now().subtract(const Duration(days: 1));
    final list = _vaccines
        .where((v) => v.nextDoseAt != null && v.nextDoseAt!.isAfter(now))
        .toList();
    list.sort((a, b) => a.nextDoseAt!.compareTo(b.nextDoseAt!));
    return list;
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _vaccines = await _repo.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVaccine(
    Vaccine vaccine, {
    required String petName,
    required bool notificationsEnabled,
  }) async {
    final id = await _repo.insert(vaccine);
    final saved = vaccine.copyWith(id: id);
    await NotificationService.instance.scheduleVaccineReminder(
      vaccine: saved,
      petName: petName,
      globalEnabled: notificationsEnabled,
    );
    await loadAll();
  }

  Future<void> updateVaccine(
    Vaccine vaccine, {
    required String petName,
    required bool notificationsEnabled,
  }) async {
    await _repo.update(vaccine);
    await NotificationService.instance.scheduleVaccineReminder(
      vaccine: vaccine,
      petName: petName,
      globalEnabled: notificationsEnabled,
    );
    await loadAll();
  }

  Future<void> deleteVaccine(int id) async {
    await _repo.delete(id);
    await NotificationService.instance.cancelVaccineReminder(id);
    await loadAll();
  }
}

