import '../models/appointment.dart';
import '../models/health_event.dart';
import 'appointment_repository.dart';
import 'medication_repository.dart';
import 'vaccine_repository.dart';

class HealthHistoryRepository {
  HealthHistoryRepository({
    VaccineRepository? vaccineRepository,
    MedicationRepository? medicationRepository,
    AppointmentRepository? appointmentRepository,
  })  : _vaccineRepo = vaccineRepository ?? VaccineRepository(),
        _medicationRepo = medicationRepository ?? MedicationRepository(),
        _appointmentRepo = appointmentRepository ?? AppointmentRepository();

  final VaccineRepository _vaccineRepo;
  final MedicationRepository _medicationRepo;
  final AppointmentRepository _appointmentRepo;

  Future<List<HealthEvent>> getHistoryForPet(int petId) async {
    final vaccines = await _vaccineRepo.getAll(petId: petId);
    final medications = await _medicationRepo.getAll(petId: petId);
    final appointments = await _appointmentRepo.getAll(petId: petId);

    final events = <HealthEvent>[];

    for (final v in vaccines) {
      events.add(
        HealthEvent(
          petId: petId,
          category: HealthEventCategory.vaccine,
          title: 'Vacina: ${v.name}',
          subtitle: v.clinic.isNotEmpty
              ? 'Aplicada em ${v.clinic}'
              : 'Vacina registrada',
          date: v.appliedAt,
          notes: v.notes,
        ),
      );
    }

    for (final m in medications) {
      events.add(
        HealthEvent(
          petId: petId,
          category: HealthEventCategory.medication,
          title: 'Medicamento: ${m.name}',
          subtitle: [
            if (m.dosage.isNotEmpty) m.dosage,
            'Horários: ${m.schedules.join(", ")}',
          ].join(' • '),
          date: m.startDate,
          notes: m.instructions,
        ),
      );
    }

    for (final a in appointments) {
      if (a.type == AppointmentType.grooming ||
          a.type == AppointmentType.vaccination) {
        // Vaccination appointments are covered or optional; keep consultations, follow-ups, exams in health history.
        if (a.type == AppointmentType.grooming) continue;
      }
      final category = a.type == AppointmentType.exam
          ? HealthEventCategory.exam
          : a.type == AppointmentType.vaccination
              ? HealthEventCategory.vaccine
              : HealthEventCategory.consultation;

      events.add(
        HealthEvent(
          petId: petId,
          category: category,
          title: '${a.type.label}: ${a.title}',
          subtitle: a.location.isNotEmpty
              ? a.location
              : (a.completed ? 'Realizado' : 'Agendado'),
          date: a.dateTime,
          notes: a.notes,
        ),
      );
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }
}

