class Vaccine {
  const Vaccine({
    this.id,
    required this.petId,
    required this.name,
    required this.appliedAt,
    this.nextDoseAt,
    this.clinic = '',
    this.notes = '',
    this.reminderEnabled = true,
    required this.createdAt,
  });

  final int? id;
  final int petId;
  final String name;
  final DateTime appliedAt;
  final DateTime? nextDoseAt;
  final String clinic;
  final String notes;
  final bool reminderEnabled;
  final DateTime createdAt;

  Vaccine copyWith({
    int? id,
    int? petId,
    String? name,
    DateTime? appliedAt,
    DateTime? nextDoseAt,
    bool clearNextDose = false,
    String? clinic,
    String? notes,
    bool? reminderEnabled,
    DateTime? createdAt,
  }) {
    return Vaccine(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      name: name ?? this.name,
      appliedAt: appliedAt ?? this.appliedAt,
      nextDoseAt: clearNextDose ? null : (nextDoseAt ?? this.nextDoseAt),
      clinic: clinic ?? this.clinic,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pet_id': petId,
      'name': name.trim(),
      'applied_at': appliedAt.toIso8601String(),
      'next_dose_at': nextDoseAt?.toIso8601String(),
      'clinic': clinic.trim(),
      'notes': notes.trim(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Vaccine.fromMap(Map<String, dynamic> map) {
    return Vaccine(
      id: map['id'] as int?,
      petId: map['pet_id'] as int,
      name: map['name'] as String? ?? '',
      appliedAt: DateTime.parse(map['applied_at'] as String),
      nextDoseAt: map['next_dose_at'] != null
          ? DateTime.tryParse(map['next_dose_at'] as String)
          : null,
      clinic: map['clinic'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      reminderEnabled: (map['reminder_enabled'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

