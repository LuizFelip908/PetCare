import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/core/database/database_helper.dart';
import 'package:petcare/core/services/demo_data_service.dart';
import 'package:petcare/data/models/appointment.dart';
import 'package:petcare/data/models/medication.dart';
import 'package:petcare/data/models/medication_log.dart';
import 'package:petcare/data/models/pet.dart';
import 'package:petcare/data/models/vaccine.dart';
import 'package:petcare/data/models/weight_record.dart';
import 'package:petcare/data/repositories/appointment_repository.dart';
import 'package:petcare/data/repositories/health_history_repository.dart';
import 'package:petcare/data/repositories/medication_repository.dart';
import 'package:petcare/data/repositories/pet_repository.dart';
import 'package:petcare/data/repositories/vaccine_repository.dart';
import 'package:petcare/data/repositories/weight_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late PetRepository petRepo;
  late VaccineRepository vaccineRepo;
  late MedicationRepository medRepo;
  late AppointmentRepository apptRepo;
  late WeightRepository weightRepo;
  late HealthHistoryRepository historyRepo;

  setUp(() async {
    dbHelper = DatabaseHelper(customPath: inMemoryDatabasePath);
    await dbHelper.database;
    petRepo = PetRepository(dbHelper: dbHelper);
    vaccineRepo = VaccineRepository(dbHelper: dbHelper);
    medRepo = MedicationRepository(dbHelper: dbHelper);
    apptRepo = AppointmentRepository(dbHelper: dbHelper);
    weightRepo = WeightRepository(dbHelper: dbHelper);
    historyRepo = HealthHistoryRepository(
      vaccineRepository: vaccineRepo,
      medicationRepository: medRepo,
      appointmentRepository: apptRepo,
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test('Pet CRUD and isolation between multiple pets', () async {
    final now = DateTime.now();
    final dogId = await petRepo.insert(
      Pet(
        name: 'Thor',
        species: PetSpecies.dog,
        breed: 'Golden',
        sex: PetSex.male,
        currentWeight: 28.0,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final catId = await petRepo.insert(
      Pet(
        name: 'Luna',
        species: PetSpecies.cat,
        breed: 'SRD',
        sex: PetSex.female,
        currentWeight: 4.1,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final pets = await petRepo.getAll();
    expect(pets.length, 2);

    await vaccineRepo.insert(
      Vaccine(
        petId: dogId,
        name: 'V10',
        appliedAt: now,
        createdAt: now,
      ),
    );

    expect((await vaccineRepo.getAll(petId: dogId)).length, 1);
    expect((await vaccineRepo.getAll(petId: catId)).length, 0);

    final fetchedDog = await petRepo.getById(dogId);
    expect(fetchedDog?.name, 'Thor');
    await petRepo.update(fetchedDog!.copyWith(name: 'Thor Silva'));
    expect((await petRepo.getById(dogId))?.name, 'Thor Silva');
  });

  test('Weight records update pet current_weight and cascade delete removes all child records', () async {
    final now = DateTime.now();
    final petId = await petRepo.insert(
      Pet(
        name: 'Mel',
        species: PetSpecies.dog,
        sex: PetSex.female,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await weightRepo.insert(
      WeightRecord(
        petId: petId,
        weightKg: 10.2,
        recordedAt: now.subtract(const Duration(days: 10)),
      ),
    );
    await weightRepo.insert(
      WeightRecord(
        petId: petId,
        weightKg: 10.8,
        recordedAt: now,
      ),
    );

    final updatedPet = await petRepo.getById(petId);
    expect(updatedPet?.currentWeight, 10.8);

    final medId = await medRepo.insert(
      Medication(
        petId: petId,
        name: 'Suplemento',
        schedules: const ['08:00', '20:00'],
        startDate: now,
        createdAt: now,
      ),
    );
    await medRepo.insertLog(
      MedicationLog(
        medicationId: medId,
        petId: petId,
        administeredAt: now,
        scheduledTime: '08:00',
      ),
    );
    await apptRepo.insert(
      Appointment(
        petId: petId,
        type: AppointmentType.consultation,
        title: 'Check-up',
        dateTime: now.add(const Duration(days: 3)),
        createdAt: now,
      ),
    );

    expect(await petRepo.countRelatedRecords(petId), 4);

    final history = await historyRepo.getHistoryForPet(petId);
    expect(history.length, 2); // 1 medication + 1 consultation

    await petRepo.delete(petId);
    expect(await petRepo.getById(petId), isNull);
    expect(await medRepo.getAll(petId: petId), isEmpty);
    expect(await medRepo.getLogs(petId: petId), isEmpty);
    expect(await apptRepo.getAll(petId: petId), isEmpty);
    expect(await weightRepo.getByPet(petId), isEmpty);
  });

  test('DemoDataService inserts and removes only demo pets', () async {
    final now = DateTime.now();
    await petRepo.insert(
      Pet(
        name: 'Rex Real',
        species: PetSpecies.dog,
        sex: PetSex.male,
        isDemo: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final demoService = DemoDataService(
      petRepository: petRepo,
      vaccineRepository: vaccineRepo,
      medicationRepository: medRepo,
      appointmentRepository: apptRepo,
      weightRepository: weightRepo,
    );

    await demoService.insertDemoData();
    expect(await petRepo.hasDemoPets(), isTrue);
    expect((await petRepo.getAll()).length, 3);

    await demoService.removeDemoData();
    expect(await petRepo.hasDemoPets(), isFalse);
    final remaining = await petRepo.getAll();
    expect(remaining.length, 1);
    expect(remaining.first.name, 'Rex Real');
  });
}

