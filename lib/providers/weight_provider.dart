import 'package:flutter/foundation.dart';

import '../data/models/weight_record.dart';
import '../data/repositories/weight_repository.dart';

class WeightProvider extends ChangeNotifier {
  WeightProvider({WeightRepository? repository})
      : _repo = repository ?? WeightRepository();

  final WeightRepository _repo;

  final Map<int, List<WeightRecord>> _recordsByPet = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<WeightRecord> forPet(int petId) =>
      List.unmodifiable(_recordsByPet[petId] ?? const []);

  Future<void> loadForPet(int petId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _recordsByPet[petId] = await _repo.getByPet(petId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(WeightRecord record) async {
    await _repo.insert(record);
    await loadForPet(record.petId);
  }

  Future<void> updateRecord(WeightRecord record) async {
    await _repo.update(record);
    await loadForPet(record.petId);
  }

  Future<void> deleteRecord(int id, int petId) async {
    await _repo.delete(id, petId);
    await loadForPet(petId);
  }
}

