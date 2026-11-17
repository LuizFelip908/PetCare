class MedicationLog {
  const MedicationLog({
    this.id,
    required this.medicationId,
    required this.petId,
    required this.administeredAt,
    this.scheduledTime = '',
    this.notes = '',
  });

  final int? id;
  final int medicationId;
  final int petId;
  final DateTime administeredAt;
  final String scheduledTime;
  final String notes;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'medication_id': medicationId,
      'pet_id': petId,
      'administered_at': administeredAt.toIso8601String(),
      'scheduled_time': scheduledTime,
      'notes': notes.trim(),
    };
  }

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      petId: map['pet_id'] as int,
      administeredAt: DateTime.parse(map['administered_at'] as String),
      scheduledTime: map['scheduled_time'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }
}

