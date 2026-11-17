import 'package:flutter/foundation.dart';

import '../data/models/pet.dart';
import '../data/models/weight_record.dart';
import '../data/repositories/pet_repository.dart';
import '../data/repositories/weight_repository.dart';

class PetProvider extends ChangeNotifier {
  PetProvider({
    PetRepository? petRepository,
    WeightRepository? weightRepository,
  })  : _petRepo = petRepository ?? PetRepository(),
        _weightRepo = weightRepository ?? WeightRepository();

  final PetRepository _petRepo;
  final WeightRepository _weightRepo;

  List<Pet> _pets = [];
  int? _selectedPetId;
  bool _isLoading = false;
  bool _hasDemo = false;

  List<Pet> get pets => List.unmodifiable(_pets);
  bool get isLoading => _isLoading;
  bool get hasDemo => _hasDemo;

  Pet? get selectedPet {
    if (_pets.isEmpty) return null;
    if (_selectedPetId != null) {
      for (final p in _pets) {
        if (p.id == _selectedPetId) return p;
      }
    }
    return _pets.first;
  }

  int? get selectedPetId => selectedPet?.id;

  void selectPet(int? petId) {
    _selectedPetId = petId;
    notifyListeners();
  }

  Pet? getById(int id) {
    for (final p in _pets) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> loadPets() async {
    _isLoading = true;
    notifyListeners();
    try {
      _pets = await _petRepo.getAll();
      _hasDemo = _pets.any((p) => p.isDemo);
      if (_pets.isNotEmpty &&
          (_selectedPetId == null ||
              !_pets.any((p) => p.id == _selectedPetId))) {
        _selectedPetId = _pets.first.id;
      } else if (_pets.isEmpty) {
        _selectedPetId = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> addPet(Pet pet) async {
    final id = await _petRepo.insert(pet);
    if (pet.currentWeight != null && pet.currentWeight! > 0) {
      await _weightRepo.insert(
        WeightRecord(
          petId: id,
          weightKg: pet.currentWeight!,
          recordedAt: DateTime.now(),
          notes: 'Peso inicial no cadastro',
        ),
      );
    }
    _selectedPetId = id;
    await loadPets();
    return id;
  }

  Future<void> updatePet(Pet pet) async {
    await _petRepo.update(pet);
    await loadPets();
  }

  Future<int> countRelatedRecords(int petId) {
    return _petRepo.countRelatedRecords(petId);
  }

  Future<void> deletePet(int id) async {
    await _petRepo.delete(id);
    if (_selectedPetId == id) {
      _selectedPetId = null;
    }
    await loadPets();
  }
}

