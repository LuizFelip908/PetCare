import '../../data/models/appointment.dart';
import '../../data/models/medication.dart';
import '../../data/models/pet.dart';
import '../../data/models/vaccine.dart';
import '../../data/models/weight_record.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/medication_repository.dart';
import '../../data/repositories/pet_repository.dart';
import '../../data/repositories/vaccine_repository.dart';
import '../../data/repositories/weight_repository.dart';

class DemoDataService {
  DemoDataService({
    PetRepository? petRepository,
    VaccineRepository? vaccineRepository,
    MedicationRepository? medicationRepository,
    AppointmentRepository? appointmentRepository,
    WeightRepository? weightRepository,
  })  : _petRepo = petRepository ?? PetRepository(),
        _vaccineRepo = vaccineRepository ?? VaccineRepository(),
        _medicationRepo = medicationRepository ?? MedicationRepository(),
        _appointmentRepo = appointmentRepository ?? AppointmentRepository(),
        _weightRepo = weightRepository ?? WeightRepository();

  final PetRepository _petRepo;
  final VaccineRepository _vaccineRepo;
  final MedicationRepository _medicationRepo;
  final AppointmentRepository _appointmentRepo;
  final WeightRepository _weightRepo;

  Future<void> insertDemoData() async {
    final now = DateTime.now();

    final dogId = await _petRepo.insert(
      Pet(
        name: 'Thor (Exemplo)',
        species: PetSpecies.dog,
        breed: 'Golden Retriever',
        sex: PetSex.male,
        birthDate: DateTime(now.year - 3, 4, 15),
        currentWeight: 28.4,
        notes: 'Registro demonstrativo. Pode ser removido nas configurações.',
        isDemo: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final catId = await _petRepo.insert(
      Pet(
        name: 'Luna (Exemplo)',
        species: PetSpecies.cat,
        breed: 'SRD',
        sex: PetSex.female,
        birthDate: DateTime(now.year - 2, 8, 10),
        currentWeight: 4.2,
        notes: 'Registro demonstrativo. Pode ser removido nas configurações.',
        isDemo: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _vaccineRepo.insert(
      Vaccine(
        petId: dogId,
        name: 'V10 (Polivalente)',
        appliedAt: now.subtract(const Duration(days: 330)),
        nextDoseAt: now.add(const Duration(days: 35)),
        clinic: 'Clínica Vet Vida',
        notes: 'Lote demonstrativo.',
        createdAt: now,
      ),
    );

    await _vaccineRepo.insert(
      Vaccine(
        petId: catId,
        name: 'V4 (Quádrupla Felina)',
        appliedAt: now.subtract(const Duration(days: 120)),
        nextDoseAt: now.add(const Duration(days: 245)),
        clinic: 'Clínica Felina Sul',
        createdAt: now,
      ),
    );

    await _medicationRepo.insert(
      Medication(
        petId: dogId,
        name: 'Condroprotetor (Exemplo)',
        dosage: '1 comprimido',
        schedules: const ['08:00', '20:00'],
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 14)),
        instructions: 'Administrar após a refeição conforme orientação veterinária.',
        createdAt: now,
      ),
    );

    await _appointmentRepo.insert(
      Appointment(
        petId: dogId,
        type: AppointmentType.consultation,
        title: 'Check-up anual',
        dateTime: now.add(const Duration(days: 2, hours: 3)),
        location: 'Clínica Vet Vida',
        notes: 'Levar carteira de vacinação.',
        createdAt: now,
      ),
    );

    await _appointmentRepo.insert(
      Appointment(
        petId: catId,
        type: AppointmentType.grooming,
        title: 'Banho e escovação',
        dateTime: now.add(const Duration(days: 5, hours: 2)),
        location: 'Pet Shop Amigo',
        createdAt: now,
      ),
    );

    // Weight history for chart demonstration
    final weights = [26.8, 27.3, 27.9, 28.4];
    for (int i = 0; i < weights.length; i++) {
      await _weightRepo.insert(
        WeightRecord(
          petId: dogId,
          weightKg: weights[i],
          recordedAt: now.subtract(Duration(days: (3 - i) * 30)),
          notes: 'Pesagem de exemplo',
        ),
      );
    }

    await _weightRepo.insert(
      WeightRecord(
        petId: catId,
        weightKg: 4.0,
        recordedAt: now.subtract(const Duration(days: 45)),
      ),
    );
    await _weightRepo.insert(
      WeightRecord(
        petId: catId,
        weightKg: 4.2,
        recordedAt: now.subtract(const Duration(days: 5)),
      ),
    );
  }

  Future<void> removeDemoData() async {
    await _petRepo.deleteDemoPets();
  }
}

